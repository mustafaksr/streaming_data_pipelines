import os
import apache_beam as beam
from apache_beam.io import fileio
from apache_beam.options.pipeline_options import PipelineOptions, GoogleCloudOptions, StandardOptions, SetupOptions
from apache_beam.transforms.trigger import AfterWatermark, AfterCount, AfterProcessingTime
from apache_beam.transforms.trigger import AccumulationMode
from apache_beam.io.mongodbio import ReadFromMongoDB,WriteToMongoDB
import json


# if DEV Loads config from .env file
from dotenv import load_dotenv
load_dotenv()
# DirectRunner for the test,  DataflowRunner for the job
TEST = False

if TEST:
  RUNNER = "DirectRunner"
  MONGODB_URI = os.environ["MONGODB_URI_TEST"]
else: 
  RUNNER = "DataflowRunner"
  MONGODB_URI = os.environ["MONGODB_URI_PRIVATE"]

PROJECT_ID = os.environ["PROJECT_ID"]
DB_USER = os.environ["MONGODB_USERNAME"]
DB_PASSWORD = os.environ["MONGODB_PASSWORD"]
BUCKET = PROJECT_ID

# MONGODB_URI = 'mongodb+srv://dbuser:dbpassword@ClusterAddress/?retryWrites=true&w=majority'


DATABASE = 'mydata'
COLLECTION = 'mycoll'

# Set up pipeline options    
options = PipelineOptions([
  '--streaming', # Add this flag to enable streaming
  '--project=' + PROJECT_ID,
  '--job_name=syntetic-pipeline-dataflow',
  '--region=us-east1',
  '--staging_location=gs://' + BUCKET + '/staging',
  '--temp_location=gs://' + BUCKET + '/temp',
  f'--runner={RUNNER}',
  '--requirements_file=requirements.txt',
  '--allow_unsafe_triggers',
  '--save_main_session', 
  '--max_num_workers=25'
])
google_cloud_options = options.view_as(GoogleCloudOptions)

INPUT_TOPIC = f"projects/{google_cloud_options.project}/topics/syntetic-data"
OUTPUT_PATH = 'gs://' + BUCKET + '/unloaded_rows'
# Define the Dataflow pipeline
class ConvertToJson(beam.DoFn):
  def process(self, element):
    try:
        row = json.loads(element.decode('utf-8'))
        yield beam.pvalue.TaggedOutput('loaded_row', row)
    except:
        yield beam.pvalue.TaggedOutput('unloaded_row', element.decode('utf-8'))

def WritePubSubToMongoDB():
    with beam.Pipeline(options=options) as p:

            rows = (p | 'ReadFromPubSub' >> beam.io.ReadFromPubSub(INPUT_TOPIC)
              | 'ParseJson' >> beam.ParDo(ConvertToJson()).with_outputs('loaded_row', 'unloaded_row'))

            (rows.unloaded_row
                | 'BatchOver10s' >> beam.WindowInto(beam.window.FixedWindows(30),
                                                    trigger=AfterProcessingTime(30),
                                                    accumulation_mode=AccumulationMode.DISCARDING)
                | 'WriteUnloadedToGCS' >> fileio.WriteToFiles(OUTPUT_PATH,
                                                            shards=1,
                                                            max_writers_per_bundle=0)
                )
            
            
            (rows.loaded_row | "WriteToMongoDB" >> WriteToMongoDB(uri=MONGODB_URI, db=DATABASE, coll=COLLECTION)
            )

if __name__=="__main__":
    WritePubSubToMongoDB()
