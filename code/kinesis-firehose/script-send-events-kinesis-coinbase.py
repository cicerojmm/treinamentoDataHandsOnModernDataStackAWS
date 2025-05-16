# import json
# import boto3
# from time import sleep
# import requests
# from datetime import datetime

# # Parâmetros configuráveis
# SLEEP_SECONDS = 15
# REGION = "us-east-1"
# STREAM_NAME = "datahandson-mds-analytics-stream"

# bases = [
#     "BTC",  # Bitcoin
#     "ETH",  # Ethereum
#     "USDT",  # Tether
#     "BNB",  # Binance Coin
#     "SOL",  # Solana
#     "XRP",  # Ripple
#     "DOGE",  # Dogecoin
#     "ADA",  # Cardano
#     "AVAX",  # Avalanche
#     "SHIB",  # Shiba Inu
# ]

# kinesis_client = boto3.client("kinesis", region_name=REGION)


# def send_batch_to_kinesis(data_list):
#     records = [
#         {
#             "Data": json.dumps(d).encode("utf-8"),
#             "PartitionKey": d.get("base", "default"),
#         }
#         for d in data_list
#     ]
#     try:
#         response = kinesis_client.put_records(Records=records, StreamName=STREAM_NAME)
#         print(f"Enviado {len(data_list)} registros para o Kinesis.")
#     except Exception as e:
#         print(f"Erro ao enviar batch para o Kinesis: {e}")


# def generate_and_send_events():
#     results = []
#     for base in bases:
#         url = f"https://api.coinbase.com/v2/prices/{base}-USD/spot"
#         try:
#             response = requests.get(url)
#             if response.status_code == 200:
#                 data = response.json().get("data", {})
#                 data["timestamp"] = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
#                 results.append(data)
#             else:
#                 print(f"⚠️ Erro ao buscar {base}: status {response.status_code}")
#         except requests.exceptions.RequestException as e:
#             print(f"⚠️ Falha ao conectar para {base}: {e}")

#     if results:
#         print(f"Lote montado com {len(results)} registros.")
#         send_batch_to_kinesis(results)
#     else:
#         print("Nenhum dado para enviar.")


# def main():
#     while True:
#         generate_and_send_events()
#         sleep(SLEEP_SECONDS)


# if __name__ == "__main__":
#     main()


import json
import boto3
from time import sleep
import requests
from datetime import datetime, timezone

# Parâmetros configuráveis
BATCH_SIZE = 10
SLEEP_SECONDS = 15
REGION = 'us-east-1'
STREAM_NAME = 'datahandson-mds-analytics-stream'

bases = [
    "BTC", "ETH", "USDT", "BNB", "SOL",
    "XRP", "DOGE", "ADA", "AVAX", "SHIB"
]

kinesis_client = boto3.client('kinesis', region_name=REGION)

def send_batch_to_kinesis(data_list):
    records = [
        {
            'Data': json.dumps(d).encode('utf-8'),
            'PartitionKey': d.get('base', 'default')
        }
        for d in data_list
    ]
    try:
        response = kinesis_client.put_records(
            Records=records,
            StreamName=STREAM_NAME
        )
        print(f"✅ Enviado {len(data_list)} registros para o Kinesis.")
    except Exception as e:
        print(f"❌ Erro ao enviar batch para o Kinesis: {e}")

def generate_and_send_events():
    results = []
    for base in bases[:BATCH_SIZE]:
        url = f"https://api.coinbase.com/v2/prices/{base}-USD/spot"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                raw = response.json().get("data", {})
                # Formatando amount como float e timestamp ISO8601
                data = {
                    "base": raw.get("base"),
                    "currency": raw.get("currency"),
                    "amount": float(raw.get("amount", 0)),
                    "timestamp": datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
                }
                results.append(data)
            else:
                print(f"⚠️ Erro ao buscar {base}: status {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"⚠️ Falha ao conectar para {base}: {e}")
        except ValueError:
            print(f"⚠️ Valor inválido para amount na base {base}")
    
    if results:
        print(f"📦 Lote montado com {len(results)} registros.")
        send_batch_to_kinesis(results)
    else:
        print("⚠️ Nenhum dado para enviar.")

def main():
    while True:
        generate_and_send_events()
        sleep(SLEEP_SECONDS)

if __name__ == "__main__":
    main()
