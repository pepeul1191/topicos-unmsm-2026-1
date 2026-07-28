from pathlib import Path
import fiftyone as fo

script_dir = Path(__file__).resolve().parent
dataset_dir = script_dir / "scripts/dataset"
yaml_path = dataset_dir / "dataset.yaml"

# Verificar si existe el archivo .yaml antes de cargar
if not yaml_path.exists():
  print(f"Error: No se encontró el archivo '{yaml_path}'")
  print("Por favor, asegúrate de crear el archivo dataset.yaml dentro de la carpeta dataset/")
else:
  dataset = fo.Dataset.from_dir(
    dataset_dir=dataset_dir,
    dataset_type=fo.types.YOLOv5Dataset,
    yaml_path=yaml_path,
    name="dataset_placas",
    overwrite=True
  )

  print(f"Se cargaron {len(dataset)} muestras con éxito.")
  session = fo.launch_app(dataset)
  session.wait()