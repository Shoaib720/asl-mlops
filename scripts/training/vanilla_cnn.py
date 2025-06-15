from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
from os import getenv
from mlflow.tensorflow import autolog
from mlflow import set_experiment, set_tracking_uri, start_run

# === MLflow Setup ===
set_tracking_uri(getenv("MLFLOW_TRACKING_URI"))
set_experiment("asl-hand-gesture-classification")
autolog()

DATA_DIR = "data/processed/train"
IMG_SIZE = 200
BATCH_SIZE = 32
EPOCHS = 10

# Load dataset
datagen = ImageDataGenerator(validation_split=0.2)

train_gen = datagen.flow_from_directory(
    DATA_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    color_mode='grayscale',
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training'
)

val_gen = datagen.flow_from_directory(
    DATA_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    color_mode='grayscale',
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation'
)

# Build CNN
model = models.Sequential([
    layers.Input(shape=(IMG_SIZE, IMG_SIZE, 1)),
    layers.Conv2D(32, (3, 3), activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D(),
    layers.Flatten(),
    layers.Dense(128, activation='relu'),
    layers.Dense(train_gen.num_classes, activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
model.summary()

# === Model Training with MLflow Tracking ===
with start_run():
    # Train model
    model.fit(train_gen, validation_data=val_gen, epochs=EPOCHS)

    # Save model
    model.save("model/asl_vanilla_cnn_model.keras")