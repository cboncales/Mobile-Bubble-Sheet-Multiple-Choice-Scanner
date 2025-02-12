import imutils
import cv2

image= cv2.imread("larry-sergey.png")
(h, w, d) = image.shape

print(h, w, d)