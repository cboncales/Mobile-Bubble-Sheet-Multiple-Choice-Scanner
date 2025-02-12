import numpy as np
import cv2
import imutils
from skimage.filters import threshold_local

image= cv2.imread("receipt.jpg")
ratio= image.shape[0]/500.0
orig= image.copy()

#resize the image
image= imutils.resize(image, height=500)