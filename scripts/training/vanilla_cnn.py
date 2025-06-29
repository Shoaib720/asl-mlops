from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
from os import getenv
from json import dump
from mlflow.keras import autolog,save_model
from mlflow import set_experiment, set_tracking_uri, start_run, log_artifacts,log_artifact, register_model, log_param
from mlflow.models.signature import infer_signature
import numpy as np

# === MLflow Setup ===
set_tracking_uri(getenv("MLFLOW_TRACKING_URI"))
set_experiment("asl-classification")
autolog(log_models=False)

DATA_DIR = "data/processed/train"
IMG_SIZE = 200
BATCH_SIZE = 32
EPOCHS = int(getenv("EPOCHS","1"))
ACCURACY_THRESHOLD = float(getenv("ACCURACY_THRESHOLD","0.6"))

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

# Extract class index mapping from generator
class_indices = train_gen.class_indices

# Optional: Print the mapping
print("Class mapping:")
for class_name, index in class_indices.items():
    print(f"{index}: {class_name}")

# Invert the mapping (if you want index → class_name)
index_to_class = {v: k for k, v in class_indices.items()}

# Save to JSON
with open("class_mapping.json", "w") as f:
    dump(index_to_class, f, indent=4)

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
with start_run() as run:
    # Train model
    history = model.fit(train_gen, validation_data=val_gen, epochs=EPOCHS, steps_per_epoch=200)
    final_val_acc = history.history['val_accuracy'][-1]
    print(f"Final validation accuracy: {final_val_acc:.4f}")
    

    sample_input = np.random.rand(BATCH_SIZE, IMG_SIZE, IMG_SIZE, 1).astype("float32")
    pred = model.predict(sample_input)
    signature = infer_signature(sample_input, pred)

    # Save model
    #model.save("model/asl_vanilla_cnn_model.keras")
    #log_model(model, artifact_path="model")
    #save_model(model, path="model")
    log_param("num_classes", train_gen.num_classes)
    log_param("samples", train_gen.samples)
    log_artifact("class_mapping.json")
    save_model(
        model,
        path="model",
        signature=signature,
        input_example=sample_input
    )
    log_artifacts("model", artifact_path="model")
    
    if final_val_acc >= ACCURACY_THRESHOLD:
        model_uri = f"runs:/{run.info.run_id}/model"
        register_model(model_uri, "asl-cnn-model")
        print("Model registered in MLflow.")
    else:
        print(f"Accuracy < {ACCURACY_THRESHOLD * 100}%, model not registered.")
    # Log it manually since autolog won't do it anymore
    # log_artifact("model/asl_vanilla_cnn_model.keras", artifact_path="model")