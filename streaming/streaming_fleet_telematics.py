import asyncio
import json
import random
from datetime import datetime
from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub import EventData

CONNECTION_STRING = "YOUR_CONNECTION_STRING_HERE"
EVENTHUB_NAME = "eh-fleet-events"

VEHICLES = [f"VH-{str(i).zfill(3)}" for i in range(1, 11)]

def generate_telemetry():
    return {
        "event_id": f"EVT-{random.randint(10000, 99999)}",
        "vehicle_id": random.choice(VEHICLES),
        "timestamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
        "speed_mph": round(random.uniform(0, 85), 2),
        "fuel_level_pct": round(random.uniform(10, 100), 2),
        "engine_temperature_c": round(random.uniform(70, 110), 2),
        "latitude": round(random.uniform(51.3, 51.6), 6),
        "longitude": round(random.uniform(-2.2, -1.8), 6)
    }

async def send_events():
    producer = EventHubProducerClient.from_connection_string(
        conn_str=CONNECTION_STRING,
        eventhub_name=EVENTHUB_NAME
    )
    async with producer:
        print("Starting fleet telemetry stream...")
        count = 0
        while count < 50:
            event_data_batch = await producer.create_batch()
            telemetry = generate_telemetry()
            event_data_batch.add(EventData(json.dumps(telemetry)))
            await producer.send_batch(event_data_batch)
            print(f"Sent event {count + 1}: Vehicle {telemetry['vehicle_id']} - Speed: {telemetry['speed_mph']} mph")
            await asyncio.sleep(1)
            count += 1
        print("Stream complete. 50 events sent.")

if __name__ == "__main__":
    asyncio.run(send_events())
