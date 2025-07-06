import pandas as pd
import numpy as np
from google.cloud import storage
import json

# Sample career dataset structure
def create_career_dataset():
    """
    Create a sample dataset for career prediction
    Features: skills, interests, academic_performance, personality_traits
    Target: career_path
    """
    
    # Define career categories
    careers = [
        'Data Scientist', 'Software Engineer', 'Product Manager', 
        'DevOps Engineer', 'UI/UX Designer', 'Business Analyst',
        'Cybersecurity Analyst', 'Machine Learning Engineer',
        'Full Stack Developer', 'Research Scientist'
    ]
    
    # Define skills (0-5 scale)
    skills = [
        'programming', 'mathematics', 'communication', 'leadership',
        'analytical_thinking', 'creativity', 'problem_solving',
        'teamwork', 'technical_writing', 'presentation'
    ]
    
    # Define interests (0-5 scale)
    interests = [
        'technology', 'research', 'business', 'design', 'management',
        'innovation', 'data_analysis', 'user_experience', 'security'
    ]
    
    # Generate sample data
    np.random.seed(42)
    n_samples = 1000
    
    data = []
    for i in range(n_samples):
        # Create realistic correlations between skills/interests and careers
        sample = {}
        
        # Personal info
        sample['age'] = np.random.randint(20, 26)
        sample['gender'] = np.random.choice(['Male', 'Female', 'Other'])
        sample['cgpa'] = np.random.uniform(6.0, 9.5)
        sample['year_of_study'] = np.random.randint(1, 5)
        
        # Skills (0-5 scale)
        for skill in skills:
            sample[f'skill_{skill}'] = np.random.randint(1, 6)
        
        # Interests (0-5 scale)
        for interest in interests:
            sample[f'interest_{interest}'] = np.random.randint(1, 6)
        
        # Personality traits
        sample['extroversion'] = np.random.randint(1, 6)
        sample['openness'] = np.random.randint(1, 6)
        sample['conscientiousness'] = np.random.randint(1, 6)
        sample['agreeableness'] = np.random.randint(1, 6)
        sample['neuroticism'] = np.random.randint(1, 6)
        
        # Academic background
        sample['branch'] = np.random.choice([
            'Computer Science', 'Information Technology', 'Electronics',
            'Mechanical', 'Civil', 'Chemical', 'Electrical'
        ])
        
        # Generate career based on realistic correlations
        career_scores = {}
        for career in careers:
            score = 0
            # Add logic for realistic career-skill correlations
            if career == 'Data Scientist':
                score += sample['skill_mathematics'] * 0.3
                score += sample['skill_analytical_thinking'] * 0.3
                score += sample['skill_programming'] * 0.2
                score += sample['interest_data_analysis'] * 0.2
            elif career == 'Software Engineer':
                score += sample['skill_programming'] * 0.4
                score += sample['skill_problem_solving'] * 0.3
                score += sample['interest_technology'] * 0.3
            elif career == 'Product Manager':
                score += sample['skill_leadership'] * 0.3
                score += sample['skill_communication'] * 0.3
                score += sample['interest_business'] * 0.2
                score += sample['interest_management'] * 0.2
            # Add more career logic...
            
            career_scores[career] = score + np.random.normal(0, 0.5)
        
        # Select career with highest score
        sample['career_path'] = max(career_scores, key=career_scores.get)
        data.append(sample)
    
    return pd.DataFrame(data)

def upload_to_gcs(df, bucket_name, file_name):
    """Upload dataset to Google Cloud Storage"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    # Convert to CSV
    csv_string = df.to_csv(index=False)
    
    # Upload to GCS
    blob = bucket.blob(file_name)
    blob.upload_from_string(csv_string, content_type='text/csv')
    
    print(f"Dataset uploaded to gs://{bucket_name}/{file_name}")
    return f"gs://{bucket_name}/{file_name}"

# Create and upload dataset
if __name__ == "__main__":
    # Create dataset
    df = create_career_dataset()
    print(f"Created dataset with {len(df)} samples")
    print(f"Features: {list(df.columns)}")
    
    # Upload to GCS (replace with your bucket name)
    gcs_path = upload_to_gcs(df, "ai-life-navigator-career-data", "career_dataset.csv")
    print(f"Dataset available at: {gcs_path}")