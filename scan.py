import numpy as np
import cv2
import imutils
from skimage.filters import threshold_local

image= cv2.imread("receipt.jpg")
ratio= image.shape[0]/500.0
orig= image.copy()

#resize the image
image= imutils.resize(image, height=500)

#grayscale
gray= cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
smooth= cv2.GaussianBlur(gray, (5, 5), 0)
edged= cv2.Canny(gray, 75, 200)
cv2.imshow("edged", edged)
cv2.waitKey(0)