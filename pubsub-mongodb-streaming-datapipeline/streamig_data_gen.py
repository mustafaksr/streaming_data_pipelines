import warnings
warnings.filterwarnings("ignore")
from google.cloud import pubsub_v1
import random
import json
import time
from faker import Faker
from dotenv import load_dotenv
import os
import shortuuid

# Load variables
load_dotenv()

project_id = os.environ["PROJECT_ID"]
topic_name = os.environ["TOPIC_NAME"]

# PUBSUB Topic
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_name)

# Create a Faker instance to generate syntetic data
fake = Faker()




product_words = "I love this product! It's exactly what I was looking for and works perfectly. The product is okay, but I wish it had more features. It gets the job done, though. This product is terrible. It doesn't work at all and I would not recommend it to anyone.".split(" ")
user_idx = [shortuuid.uuid(name=f"{i}") for i in range(101)]
prices = [round(random.uniform(1.0, 1000.0),2) for i in range(0,26)]
user_ids = [i for i in range(100)]
names = [fake.name() for i in user_ids]
surnames = [fake.last_name() for i in user_ids]
emails = [fake.email() for i in user_ids]
phones = [fake.phone_number() for i in user_ids]
addresses = [fake.address() for i in user_ids]

while True:
    # Generate syntetic name, surname, email,phone, address and comment.
    user_id = random.randint(0, 99)
    idx = user_idx[user_id] #shortuuid
    name = names[user_id]
    surname = surnames[user_id]
    email = emails[user_id]
    phone = phones[user_id]
    address = addresses[user_id]
    comment = fake.paragraph(nb_sentences=2, variable_nb_sentences=True, ext_word_list=product_words)
    # Create a JSON object with the data
    data = {
        
    }
    product_id = random.randint(0, 25)
    quantity = random.randint(1, 10)
    price = prices[product_id]
    
    event_time = int(time.time() * 1000)
    data = {
        "user_id":idx,
        "name": name,
        "surname": surname,
        "email": email,
        "phone": phone,
        "address":address,
        "product_id": product_id,
        "price": price,
        "quantity": quantity,
        "event_time": event_time,
        "comment":comment
    }
    message_data = json.dumps(data).encode("utf-8")
    future = publisher.publish(topic_path, message_data)

    print(f"Published message {future.result()}: {message_data}")
    # print(f"Published message  {message_data}\n")

    time.sleep(1)
    