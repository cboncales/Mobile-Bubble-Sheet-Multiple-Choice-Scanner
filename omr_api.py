from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
import imutils
from imutils import contours
import os
import tempfile
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

# Import the existing four_point transformation
import sys
sys.path.append('./grader')
import four_point

@app.route('/process_omr', methods=['POST'])
def process_omr():
    try:
        # Get parameters
        num_questions = int(request.form.get('num_questions', 5))
        
        # Get uploaded image
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No image file selected'}), 400
        
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp_file:
            file.save(tmp_file.name)
            temp_path = tmp_file.name
        
        try:
            # Process the OMR image
            answers = process_omr_image(temp_path, num_questions)
            
            # Clean up temporary file
            os.unlink(temp_path)
            
            return jsonify({
                'success': True,
                'answers': answers,
                'total_questions': num_questions
            })
            
        except Exception as e:
            # Clean up temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            raise e
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def process_omr_image(image_path, num_questions):
    """
    Process OMR image and return detected answers.
    Based on the existing grader.py logic but made more flexible.
    """
    # Read the image
    image = cv2.imread(image_path)
    if image is None:
        raise Exception("Could not read image file")
    
    # Preprocess image
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edged = cv2.Canny(blurred, 75, 200)
    
    # Find contours
    cnts = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    docCnt = None

    # Find the document contour (largest rectangular contour)
    if len(cnts) > 0:
        cnts = sorted(cnts, key=cv2.contourArea, reverse=True)
        
        for c in cnts:
            peri = cv2.arcLength(c, True)
            approx = cv2.approxPolyDP(c, 0.02 * peri, True)
            
            if len(approx) == 4:
                docCnt = approx
                break

    if docCnt is None:
        raise Exception("No answer sheet document found in image")

    # Apply perspective transform
    paper = four_point.four_point_transform(image, docCnt.reshape(4, 2))
    warped = four_point.four_point_transform(gray, docCnt.reshape(4, 2))
    
    # Apply threshold
    thresh = cv2.threshold(warped, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]

    # Find question bubbles
    cnts = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    questionCnts = []

    # Filter for circular/bubble-like contours
    for c in cnts:
        (x, y, w, h) = cv2.boundingRect(c)
        ar = w / float(h)
        
        # Adjust these parameters based on your answer sheet format
        if w >= 20 and h >= 20 and ar >= 0.9 and ar <= 1.1:
            questionCnts.append(c)

    if len(questionCnts) == 0:
        raise Exception("No answer bubbles found in the image")

    # Sort question contours from top to bottom
    questionCnts = contours.sort_contours(questionCnts, method="top-to-bottom")[0]
    
    # Calculate expected bubbles per question (A, B, C, D, E = 5)
    bubbles_per_question = 5
    expected_total_bubbles = num_questions * bubbles_per_question
    
    # If we have more bubbles than expected, take only the first ones
    if len(questionCnts) > expected_total_bubbles:
        questionCnts = questionCnts[:expected_total_bubbles]
    elif len(questionCnts) < expected_total_bubbles:
        # If we have fewer bubbles, we'll work with what we have
        # and mark missing questions as unanswered
        pass

    selected_answers = []

    # Process each question (group of 5 bubbles)
    for q in range(num_questions):
        start_idx = q * bubbles_per_question
        end_idx = start_idx + bubbles_per_question
        
        if start_idx >= len(questionCnts):
            # No more bubbles available for this question
            selected_answers.append("N/A")
            continue
            
        # Get the bubbles for this question
        question_bubbles = questionCnts[start_idx:min(end_idx, len(questionCnts))]
        
        if len(question_bubbles) < bubbles_per_question:
            # Not enough bubbles for this question
            selected_answers.append("N/A")
            continue
            
        # Sort bubbles left to right for this question
        question_bubbles = contours.sort_contours(question_bubbles)[0]
        
        bubbled = None
        
        # Check each bubble to find the most filled one
        for (j, c) in enumerate(question_bubbles):
            mask = np.zeros(thresh.shape, dtype="uint8")
            cv2.drawContours(mask, [c], -1, (255, 255, 255), -1)
            mask = cv2.bitwise_and(thresh, thresh, mask=mask)
            total = cv2.countNonZero(mask)
            
            if bubbled is None or total > bubbled[0]:
                bubbled = (total, j)
        
        # Convert bubble index to letter
        if bubbled is not None and bubbled[1] < 5:
            answer_letter = chr(ord('A') + bubbled[1])
            selected_answers.append(answer_letter)
        else:
            selected_answers.append("N/A")
    
    return selected_answers

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': 'OMR API is running'})

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        'message': 'OMR Processing API',
        'version': '1.0.0',
        'endpoints': {
            'process_omr': 'POST /process_omr - Process OMR answer sheet',
            'health': 'GET /health - Health check'
        }
    })

if __name__ == '__main__':
    print("Starting OMR Processing API...")
    print("Endpoints:")
    print("  POST /process_omr - Process OMR answer sheet")
    print("  GET /health - Health check")
    print("  GET / - API information")
    
    app.run(debug=True, host='0.0.0.0', port=5000) 