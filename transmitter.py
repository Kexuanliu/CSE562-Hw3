import numpy as np
from PIL import Image
import cv2

def tobits(s):
    result = []
    for c in s:
        bits = bin(ord(c))[2:]
        bits = '00000000'[len(bits):] + bits
        result.extend([int(b) for b in bits[2:]])
    return ''.join([str(r) for r in result])

def run():
    inputString = "dog"
    delta_alpha = 0.1
    framerate = 60
    modulation_length = 16
    bit_string = tobits(inputString)
    bit_string = "1" + bit_string
    print(bit_string)
    base = Image.open('husky.jpg')
    data = np.zeros((base.height, base.width, 3), dtype=np.uint8)
    #data = np.ones((base.height, base.width, 3), dtype=np.uint8)
    foreground = Image.fromarray(data, )       # black image
    dimness = int(delta_alpha * 255)
    mask_img = Image.fromarray(np.ones((base.height, base.width),dtype=np.uint8) * dimness,)
    #img = Image.composite(foreground, base, mask_img)
    img = Image.composite(base, foreground, mask_img)
    images = []
    for bit in bit_string:
        assert bit == "0" or bit == "1"
        if bit == "1":
            alpha_matrix = np.ones(modulation_length)
            for i in np.arange(modulation_length):
                if i % 2 == 0:
                    alpha_matrix[i] = 0
                else:
                    alpha_matrix[i] = 1
            tmpImages = []
            for j in np.arange(modulation_length):
                if alpha_matrix[j] == 0:
                    tmpImages.append(img)
                else:
                    tmpImages.append(foreground)
            images.extend(tmpImages)
        else:
            alpha_matrix = np.ones(modulation_length)
            for i in np.arange(modulation_length):
                if i % 3 == 0:
                    alpha_matrix[i] = 0
                else:
                    alpha_matrix[i] = 1
            tmpImages = []
            for j in np.arange(modulation_length):
                if alpha_matrix[j] == 0:
                    tmpImages.append(img)
                else:
                    tmpImages.append(foreground)
            images.extend(tmpImages)

    fourcc = cv2.VideoWriter_fourcc(*'avc1')
    video = cv2.VideoWriter(f"{inputString}.mp4", fourcc, framerate, (base.width, base.height))
    for img in images:
        video.write(cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR))
    video.release()


if __name__ == '__main__':
    run()
