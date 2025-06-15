import os
import cv2
from tqdm import tqdm

RAW_DIR = "data/raw/train"
PROCESSED_DIR = "data/processed/train"
IMG_SIZE = 200

def transform_image(image_path):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None
    resized = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    return resized

def process_all():
    os.makedirs(PROCESSED_DIR, exist_ok=True)
    for label in os.listdir(RAW_DIR):
        input_dir = os.path.join(RAW_DIR, label)
        output_dir = os.path.join(PROCESSED_DIR, label)
        os.makedirs(output_dir, exist_ok=True)
        for fname in tqdm(os.listdir(input_dir), desc=f"Processing {label}"):
            src = os.path.join(input_dir, fname)
            dst = os.path.join(output_dir, fname)
            img = transform_image(src)
            if img is not None:
                cv2.imwrite(dst, img)

if __name__ == "__main__":
    process_all()
