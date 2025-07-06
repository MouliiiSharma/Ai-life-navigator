from google.cloud import aiplatform
import time

def create_automl_tabular_training_job(
    project_id: str,
    location: str,
    dataset_gcs_path: str,
    model_display_name: str,
    target_column: str = "career_path"
):
    """
    Create and start an AutoML Tabular training job for career prediction
    """
    
    # Initialize AI Platform
    aiplatform.init(project=project_id, location=location)
    
    # Create dataset
    print("Creating dataset...")
    dataset = aiplatform.TabularDataset.create(
        display_name=f"{model_display_name}_dataset",
        gcs_source=dataset_gcs_path,
    )
    
    print(f"Dataset created: {dataset.display_name}")
    print(f"Dataset ID: {dataset.name}")
    
    # Define training job
    print("Creating AutoML training job...")
    
    try:
        # Create the training job object
        job = aiplatform.AutoMLTabularTrainingJob(
            display_name=f"{model_display_name}_training_job",
            optimization_prediction_type="classification",
            optimization_objective="minimize-log-loss",
            column_specs={
                "age": "numeric",
                "gender": "categorical", 
                "cgpa": "numeric",
                "year_of_study": "numeric",
                "branch": "categorical",
                "skill_programming": "numeric",
                "skill_mathematics": "numeric",
                "skill_communication": "numeric",
                "skill_leadership": "numeric",
                "skill_analytical_thinking": "numeric",
                "skill_creativity": "numeric",
                "skill_problem_solving": "numeric",
                "skill_teamwork": "numeric",
                "skill_technical_writing": "numeric",
                "skill_presentation": "numeric",
                "interest_technology": "numeric",
                "interest_research": "numeric",
                "interest_business": "numeric",
                "interest_design": "numeric",
                "interest_management": "numeric",
                "interest_innovation": "numeric",
                "interest_data_analysis": "numeric",
                "interest_user_experience": "numeric",
                "interest_security": "numeric",
                "extroversion": "numeric",
                "openness": "numeric",
                "conscientiousness": "numeric",
                "agreeableness": "numeric",
                "neuroticism": "numeric",
                target_column: "categorical",
            }
        )
        
        print("Training job object created successfully")
        
        # Start training job
        print("Starting training job...")
        model = job.run(
            dataset=dataset,
            target_column=target_column,
            training_fraction_split=0.8,
            validation_fraction_split=0.1,
            test_fraction_split=0.1,
            model_display_name=model_display_name,
            budget_milli_node_hours=1000,  # 1 hour budget
            sync=False  # Don't wait for completion
        )
        
        # Wait a moment for the job to be fully initialized
        time.sleep(5)
        
        print(f"✅ Training job submitted successfully!")
        print(f"Job Display Name: {job.display_name}")
        
        # Try to get job details
        try:
            print(f"Job State: {job.state}")
            print(f"Job Resource Name: {job.resource_name}")
        except Exception as e:
            print(f"⚠️ Job details not immediately available: {str(e)}")
            print("This is normal - the job is being initialized")
        
        print("\n🔍 To monitor your training job:")
        print(f"1. Go to: https://console.cloud.google.com/vertex-ai/training/custom-jobs?project={project_id}")
        print(f"2. Look for job named: {model_display_name}_training_job")
        print("3. Or check: Vertex AI > Training > AutoML")
        
        return job, model
        
    except Exception as e:
        print(f"❌ Error creating/running training job: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        
        # Try alternative approach
        print("\n🔄 Trying alternative approach...")
        return create_automl_training_alternative(
            project_id, location, dataset, model_display_name, target_column
        )


def create_automl_training_alternative(project_id, location, dataset, model_display_name, target_column):
    """
    Alternative approach using direct API calls
    """
    try:
        # Simplified AutoML training job
        job = aiplatform.AutoMLTabularTrainingJob(
            display_name=f"{model_display_name}_training_job_v2",
            optimization_prediction_type="classification",
        )
        
        print("Alternative training job created")
        
        # Run with minimal parameters
        model = job.run(
            dataset=dataset,
            target_column=target_column,
            budget_milli_node_hours=1000,
            sync=False
        )
        
        print("✅ Alternative training job submitted!")
        return job, model
        
    except Exception as e:
        print(f"❌ Alternative approach also failed: {str(e)}")
        return None, None


def list_training_jobs(project_id: str, location: str):
    """
    List all training jobs to verify submission
    """
    aiplatform.init(project=project_id, location=location)
    
    try:
        print("\n📋 Listing all training jobs...")
        
        # List AutoML jobs
        jobs = aiplatform.AutoMLTabularTrainingJob.list()
        
        if jobs:
            print(f"Found {len(jobs)} AutoML training jobs:")
            for job in jobs:
                print(f"  - {job.display_name} | State: {job.state}")
        else:
            print("No AutoML training jobs found")
            
        # Also check custom jobs
        custom_jobs = aiplatform.CustomJob.list()
        if custom_jobs:
            print(f"Found {len(custom_jobs)} custom jobs:")
            for job in custom_jobs:
                print(f"  - {job.display_name} | State: {job.state}")
                
    except Exception as e:
        print(f"Error listing jobs: {str(e)}")


def check_dataset_and_permissions(project_id: str, location: str, dataset_gcs_path: str):
    """
    Check if dataset exists and permissions are correct
    """
    print("\n🔍 Checking dataset and permissions...")
    
    try:
        # Check if we can access the dataset
        from google.cloud import storage
        
        # Parse GCS path
        bucket_name = dataset_gcs_path.replace("gs://", "").split("/")[0]
        file_path = "/".join(dataset_gcs_path.replace("gs://", "").split("/")[1:])
        
        print(f"Bucket: {bucket_name}")
        print(f"File: {file_path}")
        
        # Try to access the file
        client = storage.Client(project=project_id)
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(file_path)
        
        if blob.exists():
            print("✅ Dataset file exists and is accessible")
            return True
        else:
            print("❌ Dataset file not found")
            return False
            
    except Exception as e:
        print(f"❌ Error checking dataset: {str(e)}")
        return False


# Example usage
if __name__ == "__main__":
    # Configuration
    PROJECT_ID = "ai-life-navigator-27187"
    LOCATION = "us-central1"
    DATASET_GCS_PATH = "gs://ai-life-navigator-career-data/career_dataset.csv"
    MODEL_DISPLAY_NAME = "career-prediction-model"
    
    # Check dataset first
    dataset_ok = check_dataset_and_permissions(PROJECT_ID, LOCATION, DATASET_GCS_PATH)
    
    if not dataset_ok:
        print("❌ Please fix dataset issues before proceeding")
        exit(1)
    
    # Start training
    print("\n🚀 Starting training job...")
    training_job, model = create_automl_tabular_training_job(
        project_id=PROJECT_ID,
        location=LOCATION,
        dataset_gcs_path=DATASET_GCS_PATH,
        model_display_name=MODEL_DISPLAY_NAME,
    )
    
    # List jobs to verify
    list_training_jobs(PROJECT_ID, LOCATION)
    
    if training_job:
        print(f"\n✅ SUCCESS! Training job created.")
        print(f"Monitor at: https://console.cloud.google.com/vertex-ai?project={PROJECT_ID}")
    else:
        print("\n❌ Failed to create training job. Check the errors above.")