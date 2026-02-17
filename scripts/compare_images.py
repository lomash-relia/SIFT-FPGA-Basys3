# import numpy as np
# from PIL import Image

# ORIGINAL_HEX = "image.hex"
# BLURRED_HEX  = "blurred_image.hex"
# OUTPUT_PNG   = "dog_output.png"

# def hex_to_array(path):
#     with open(path, "r") as f:
#         values = [int(h, 16) for h in f.read().split()]
#     size = int(len(values) ** 0.5)
#     return np.array(values, dtype=np.float32).reshape((size, size))

# original = hex_to_array(ORIGINAL_HEX)
# blurred  = hex_to_array(BLURRED_HEX)

# dog = original - blurred
# dog = (dog - dog.min()) / (dog.max() - dog.min()) * 255
# Image.fromarray(dog.astype(np.uint8)).save(OUTPUT_PNG)

import numpy as np
from PIL import Image

# 1. Load the data
# Adjust the filename if yours is different
data = np.loadtxt('dog_output.txt')

# 2. Reshape to 128x128
# This matches the parameters in your Verilog
img_array = data.reshape((128, 128))

# 3. Visualization Strategy: Normalization
# DoG values are signed (e.g., -20 to +20). 
# To see them as grayscale (0-255), we shift and scale them.
# We map the minimum value to 0 and the maximum to 255.
img_min = img_array.min()
img_max = img_array.max()
img_normalized = 255 * (img_array - img_min) / (img_max - img_min)

# 4. Save the image
img = Image.fromarray(img_normalized.astype(np.uint8))
img.save('dog_result.png')
img.show()
print(f"Image saved! Range was {img_min} to {img_max}")