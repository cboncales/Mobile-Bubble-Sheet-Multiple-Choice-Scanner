import imutils
import cv2

image= cv2.imread("larry-sergey.png")
(h, w, d) = image.shape

#print(h, w, d)

(B, G, R)= image[100, 50]
print(B, G, R)