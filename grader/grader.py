import cv2
import numpy as np
import imutils
from imutils import contours
import four_point

Answer_key= {0: 1, 1: 4, 2: 0, 3: 3, 4: 1}

image= cv2.imread("C:/Users/asus/Desktop/THESIS/Mobile Bubble Sheet Multiple Choice Scanner/grader/omr.png")
gray= cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
blurred= cv2.GaussianBlur(gray, (5, 5), 0)
edged= cv2.Canny(blurred, 75, 200)
cnts= cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
cnts= imutils.grab_contours(cnts)
docCnt= None

if len(cnts)>0:
    cnts= sorted(cnts, key= cv2.contourArea, reverse= True)
    
    for c in cnts:
        peri= cv2.arcLength(c, True)
        approx= cv2.approxPolyDP(c, 0.02*peri, True)
        
        if len(approx)==4:
            docCnt= approx
            break

if docCnt is not None:
    paper = four_point.four_point_transform(image, docCnt.reshape(4, 2))
    warped = four_point.four_point_transform(gray, docCnt.reshape(4, 2))
    cv2.imshow("edged", edged)
    cv2.waitKey(0)
else:
    print("No contour with 4 points found.")