import csv
import random
from datetime import datetime, timedelta

def generate_fleet_data(filename, num_records=100):
    vehicles = [f"VH-{str(i).zfill(3)}" for i in range(1, 11)]
    
    with open(filename, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'event_id', 'vehicle_id', 'timestamp', 'speed_mph',
            'fuel_level_pct', 'engine_temperature_c', 'latitude', 'longitude'
        ])
        writer.writeheader()
        
        base_time = datetime(2024, 6, 10, 6, 0, 0)
        
        for i in range(num_records):
            writer.writerow({
                'event_id': f"EVT-{str(i+1).zfill(5)}",
                'vehicle_id': random.choice(vehicles),
                'timestamp': (base_time + timedelta(minutes=i*5)).strftime('%Y-%m-%d %H:%M:%S'),
                'speed_mph': round(random.uniform(0, 85), 2),
                'fuel_level_pct': round(random.uniform(10, 100), 2),
                'engine_temperature_c': round(random.uniform(70, 110), 2),
                'latitude': round(random.uniform(51.3, 51.6), 6),
                'longitude': round(random.uniform(-2.2, -1.8), 6)
            })
    print(f"Generated {num_records} records in {filename}")

generate_fleet_data('fleet_batch_001.csv', 100)
generate_fleet_data('fleet_batch_002.csv', 100)
print("Done. Two CSV files created.")