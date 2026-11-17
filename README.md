# Online-Breach Impact Estimator

## Mission and problem
My mission is to use machine learning and cybersecurity to protect individuals and organisations from online threats, promote digital safety, and give communities the knowledge they need to stay secure online.
When an organisation detects a cyberattack (hacking, malware or phishing), it knows *how* it was attacked long before forensics confirms *how many* records were stolen.
This project predicts the number of records an online attack probably exposed, from what is known at detection time.
Incident responders can then size their warnings to affected people, and their escalation, sooner.

## Dataset
**VERIS Community Database (VCDB)** by Verizon's risk team: real, publicly reported security incidents coded in the VERIS framework (CC BY-SA 4.0). Source: https://github.com/vz-risk/VCDB (file `data/csv/vcdb.csv.zip`). Field definitions: https://verisframework.org.
I kept online-threat incidents (Hacking, Malware, Social) from 2005 onwards with a known record count: **1,451 incidents, 12 features** (3 numeric, 9 categorical). The target is `records_exposed`, modelled as log10.

## API (Swagger UI)
**https://YOUR-SERVICE.onrender.com/docs** ← replace with your Render URL

## Video demo
**https://youtu.be/YOUR-VIDEO-ID** ← replace with your YouTube link

## How to run the mobile app
_Steps added with the Flutter app._

---

### Repository layout
```
summative/
├── pyproject.toml, uv.lock          uv project (Python 3.12)
├── linear_regression/
│   ├── multivariate.ipynb           EDA, 4 models, loss curve, comparison, saves the best model
│   └── data/                        raw VCDB zip + the modelling table built from it
├── API/
│   ├── prediction.py                FastAPI: /predict, /retrain, /docs
│   ├── requirements.txt             exported with uv
│   ├── best_model.pkl               Random Forest pipeline (preprocessing + model)
│   ├── training_data.csv            original data, used when retraining
│   └── sample_new_incidents.csv     example upload for /retrain
└── FlutterApp/
```

### Run the API locally
```bash
cd summative
uv sync
cd API
uv run uvicorn prediction:app --reload      # open http://127.0.0.1:8000/docs
```

### Deploy on Render
New **Web Service** → connect this repo →
* **Root Directory:** `summative/API`
* **Build Command:** `pip install -r requirements.txt`
* **Start Command:** `uvicorn prediction:app --host 0.0.0.0 --port $PORT`
* **Environment variable:** `PYTHON_VERSION` = `3.12.8`
* Plan: Free

### Regenerate requirements.txt
```bash
cd summative
uv export --format requirements.txt --no-hashes --no-dev --no-emit-project -o API/requirements.txt
```
