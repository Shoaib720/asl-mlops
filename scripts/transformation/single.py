import cv2
from cv2 import imread, IMREAD_GRAYSCALE, resize

IMG_SIZE = 200

def transform_single_image(image_path):
    img = imread(image_path, IMREAD_GRAYSCALE)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")
    resized = resize(img, (IMG_SIZE, IMG_SIZE))
    normalized = resized / 255.0
    return normalized.reshape(1, IMG_SIZE, IMG_SIZE, 1)

if __name__ == "__main__":
    import sys
    import matplotlib.pyplot as plt

    if len(sys.argv) != 2:
        print("Usage: python transform_single.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    transformed = transform_single_image(image_path)
    
    # Show the transformed image
    plt.imshow(transformed[0, :, :, 0], cmap='gray')
    plt.title("Transformed Image (200x200)")
    plt.axis('off')
    plt.show()
