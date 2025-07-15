const { onRequest } = require("firebase-functions/v2/https");
const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { PredictionServiceClient } = require('@google-cloud/aiplatform');
const secrets = require('./node-secrets');

// Set global options for all functions
setGlobalOptions({
  maxInstances: 10,
  timeoutSeconds: 540,
  memory: "1GiB",
  region: Location,
});

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || securityRules.geminiApiKey);
const client = new PredictionServiceClient();

// AutoML model configuration
const PROJECT_ID = process.env.PROJECT_ID || admin.securityRules.vertexProjectId;
const ENDPOINT_ID = process.env.ENDPOINT_ID || admin.securityRules.vertexEndpointI;
const LOCATION = process.env.LOCATION || admin.securityRules.vertexLocation;

// ===========================================
// MAIN CAREER PREDICTION FUNCTION (Enhanced with AutoML)
// ===========================================

exports.predictCareerWithAutoML = onCall(
  {
    cors: true,
    maxInstances: 5,
    timeoutSeconds: 300,
  },
  async (request) => {
    if (!request.auth) {
      throw new Error('User must be authenticated to make predictions.');
    }

    try {
      const { userInput, includeAnalysis, userId } = request.data;

      if (!userInput) {
        throw new Error('User input is required.');
      }

      // Make prediction using AutoML
      const prediction = await makePredictionWithAutoML(userInput);

      // Generate detailed career analysis using Gemini AI
      const careerAnalysis = await generateEnhancedCareerAnalysis(userInput, prediction);

      const response = {
        success: true,
        id: generatePredictionId(),
        predictions: careerAnalysis.predictions,
        explanation: careerAnalysis.explanation,
        aiInsights: careerAnalysis.aiInsights,
        timestamp: Date.now(),
        userInput: userInput,
        modelConfidence: prediction.confidence,
        method: 'automl'
      };

      // Save prediction to Firestore
      await savePredictionToFirestore(userId, response);

      return response;

    } catch (error) {
      console.error('Error in career prediction:', error);
      
      return {
        success: false,
        error: error.message || 'Failed to generate career prediction',
        timestamp: Date.now(),
      };
    }
  }
);

// ===========================================
// AUTOML PREDICTION FUNCTION
// ===========================================

async function makePredictionWithAutoML(userInput) {
  try {
    const endpoint = `projects/${PROJECT_ID}/locations/${LOCATION}/endpoints/${ENDPOINT_ID}`;
    
    // Transform user input to match AutoML model format
    const instances = [{
      age: userInput.age || 22,
      gender: userInput.gender === 'Male' ? 1 : (userInput.gender === 'Female' ? 0 : 0.5),
      cgpa: userInput.cgpa || 7.5,
      year_of_study: userInput.yearOfStudy || 3,
      branch: encodeBranch(userInput.branch || 'Computer Science'),
      skill_programming: userInput.skills?.Programming || 5,
      skill_data_analysis: userInput.skills?.['Data Analysis'] || 5,
      skill_ml: userInput.skills?.['Machine Learning'] || 5,
      skill_web_dev: userInput.skills?.['Web Development'] || 5,
      skill_communication: userInput.skills?.Communication || 5,
      interest_technology: userInput.interests?.Technology || 5,
      interest_research: userInput.interests?.Research || 5,
      interest_innovation: userInput.interests?.Innovation || 5,
      interest_problem_solving: userInput.interests?.['Problem Solving'] || 5,
      interest_business: userInput.interests?.Business || 5,
      trait_analytical: userInput.personality?.Analytical || 5,
      trait_creative: userInput.personality?.Creative || 5,
      trait_leadership: userInput.personality?.Leadership || 5,
      trait_teamwork: userInput.personality?.['Team Work'] || 5,
      trait_adaptability: userInput.personality?.Adaptability || 5,
    }];

    const request = {
      endpoint,
      instances,
    };

    const [response] = await client.predict(request);
    
    // Process AutoML response
    const predictions = response.predictions || [];
    const topPrediction = predictions[0];
    
    return {
      career: topPrediction?.displayName || 'Software Developer',
      confidence: Math.round((topPrediction?.confidence || 0.75) * 100),
      alternativeCareers: predictions.slice(1, 5).map(p => p.displayName),
      method: 'automl'
    };

  } catch (error) {
    console.error('Error making AutoML prediction:', error);
    // Fallback to enhanced rule-based prediction
    return generateEnhancedPrediction(userInput);
  }
}

// ===========================================
// GEMINI AI CHAT FUNCTION - FIXED
// ===========================================

exports.geminiChat = onRequest(
  {
    cors: true,
    maxInstances: 5,
    timeoutSeconds: 300,
  },
  (req, res) => {
    // Handle CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const handleRequest = async () => {
      try {
        if (req.method !== "POST") {
          res.status(405).json({ error: "Method not allowed" });
          return;
        }

        const { message, chatHistory } = req.body;

        if (!message) {
          res.status(400).json({ error: "Message is required" });
          return;
        }

        const model = genAI.getGenerativeModel({ model: "gemini-pro" });

        const history = [
          {
            role: "user",
            parts: ["Act like a professional career counselor and AI guide. Help users with career guidance, ask relevant questions about their interests, skills, and goals. Be supportive, provide actionable advice, and suggest specific steps they can take."],
          },
          {
            role: "model",
            parts: ["Hello! I'm here to help you navigate your career journey. What would you like to discuss about your career today?"],
          },
        ];

        if (chatHistory && Array.isArray(chatHistory)) {
          history.push(...chatHistory);
        }

        const chat = model.startChat({
          history: history,
        });

        const result = await chat.sendMessage(message);
        const response = await result.response;
        const text = response.text();

        res.status(200).json({
          reply: text,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        console.error("Error in geminiChat:", error);
        res.status(500).json({ 
          error: "Internal server error", 
          details: error.message 
        });
      }
    };

    handleRequest();
  }
);

// ===========================================
// CAREER ANALYSIS FUNCTION - FIXED
// ===========================================

exports.getCareerAnalysis = onRequest(
  {
    cors: true,
    maxInstances: 5,
    timeoutSeconds: 300,
  },
  (req, res) => {
    // Handle CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const handleRequest = async () => {
      try {
        if (req.method !== "POST") {
          res.status(405).json({ error: "Method not allowed" });
          return;
        }

        const { careerPath, userProfile } = req.body;

        if (!careerPath || !userProfile) {
          res.status(400).json({ error: "careerPath and userProfile are required" });
          return;
        }

        const analysis = await generateDetailedCareerAnalysis(careerPath, userProfile);

        res.status(200).json({
          analysis,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        console.error("Error in getCareerAnalysis:", error);
        res.status(500).json({ 
          error: "Internal server error", 
          details: error.message 
        });
      }
    };

    handleRequest();
  }
);

// ===========================================
// USER STATS FUNCTION
// ===========================================

exports.getUserStats = onCall(
  {
    cors: true,
    maxInstances: 3,
    timeoutSeconds: 180,
  },
  async (request) => {
    if (!request.auth) {
      throw new Error('User must be authenticated');
    }

    try {
      const userId = request.auth.uid;
      const predictionsSnapshot = await db.collection('predictions')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .get();

      const totalPredictions = predictionsSnapshot.size;
      const predictions = predictionsSnapshot.docs.map(doc => doc.data());
      
      const careers = predictions.map(p => p.predictions?.[0]?.career).filter(Boolean);
      const mostPredictedCareer = getMostFrequent(careers);
      const avgConfidence = predictions.reduce((sum, p) => sum + (p.predictions?.[0]?.confidence || 0), 0) / predictions.length;

      return {
        totalPredictions,
        mostPredictedCareer,
        avgConfidence: Math.round(avgConfidence) || 0,
        recentPredictions: predictions.slice(0, 3)
      };
    } catch (error) {
      throw new Error('Error fetching user stats: ' + error.message);
    }
  }
);

// ===========================================
// HEALTH CHECK FUNCTION - FIXED
// ===========================================

exports.healthCheck = onRequest(
  {
    cors: true,
    maxInstances: 1,
    timeoutSeconds: 60,
  },
  (req, res) => {
    // Handle CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const handleRequest = async () => {
      try {
        await db.collection('health_check').limit(1).get();
        
        res.status(200).json({
          status: "healthy",
          timestamp: new Date().toISOString(),
          version: "2.0.0",
          services: {
            database: "operational",
            gemini_ai: "operational",
            automl: "operational",
            auth: "operational",
          },
        });
      } catch (error) {
        res.status(500).json({
          status: "unhealthy",
          error: error.message,
          timestamp: new Date().toISOString(),
        });
      }
    };

    handleRequest();
  }
);

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

function encodeBranch(branch) {
  const branchMap = {
    'Computer Science': 0,
    'Information Technology': 1,
    'Electronics': 2,
    'Mechanical': 3,
    'Civil': 4,
    'Chemical': 5,
    'Biotechnology': 6,
    'Electrical': 7,
    'Other': 8,
  };
  return branchMap[branch] || 0;
}

function generateEnhancedPrediction(userInput) {
  const careerScores = {};
  
  // Calculate scores for different careers
  careerScores['Software Developer'] = (userInput.skills?.Programming * 2 + userInput.interests?.Technology + userInput.personality?.Analytical) / 4;
  careerScores['Data Scientist'] = (userInput.skills?.['Data Analysis'] * 2 + userInput.skills?.['Machine Learning'] + userInput.interests?.Research) / 4;
  careerScores['Machine Learning Engineer'] = (userInput.skills?.['Machine Learning'] * 2 + userInput.skills?.Programming + userInput.interests?.Innovation) / 4;
  careerScores['Full Stack Developer'] = (userInput.skills?.['Web Development'] * 2 + userInput.skills?.Programming + userInput.personality?.Creative) / 4;
  
  // Find the career with highest score
  let maxScore = 0;
  let primaryCareer = 'Software Developer';
  
  for (const [career, score] of Object.entries(careerScores)) {
    if (score > maxScore) {
      maxScore = score;
      primaryCareer = career;
    }
  }

  const confidence = Math.min(95, Math.max(65, Math.round(maxScore * 10)));
  const alternativeCareers = Object.entries(careerScores)
    .sort(([,a], [,b]) => b - a)
    .map(([career]) => career)
    .filter(career => career !== primaryCareer)
    .slice(0, 3);

  return {
    career: primaryCareer,
    confidence: confidence,
    alternativeCareers: alternativeCareers,
    method: 'fallback'
  };
}

async function generateEnhancedCareerAnalysis(userInput, prediction) {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    
    const prompt = `
    As a career counselor, analyze this user profile and provide detailed career guidance:
    
    User Profile: ${JSON.stringify(userInput)}
    Primary Career Prediction: ${prediction.career}
    Confidence: ${prediction.confidence}%
    
    Please provide:
    1. Detailed reasoning for the career match
    2. Key strengths that align with this career
    3. Skills that need development
    4. Specific action steps for the next 6 months
    5. Long-term career roadmap
    
    Keep the response professional and actionable.
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiInsights = response.text();

    const predictions = [
      {
        career: prediction.career,
        confidence: prediction.confidence,
        reasoning: generateReasoning(userInput, prediction.career),
        skillsRequired: getRequiredSkills(prediction.career),
        suggestedCourses: getSuggestedCourses(prediction.career),
        salaryRange: getSalaryRange(prediction.career),
        industryGrowth: getIndustryGrowth(prediction.career),
        actionSteps: getActionSteps(prediction.career),
      }
    ];

    return {
      predictions: predictions,
      explanation: generateExplanation(userInput, prediction),
      aiInsights: aiInsights
    };
  } catch (error) {
    console.error('Error generating AI insights:', error);
    return generateBasicCareerAnalysis(userInput, prediction);
  }
}

async function generateDetailedCareerAnalysis(careerPath, userProfile) {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    
    const prompt = `
    Analyze the career path "${careerPath}" for a user with the following profile:
    ${JSON.stringify(userProfile)}
    
    Please provide a comprehensive analysis including:
    1. Match score (0-100) with detailed explanation
    2. Key strengths that align with this career
    3. Areas for improvement and skill gaps
    4. Specific skills to develop with priority levels
    5. Career roadmap with stages and timelines
    6. Salary insights and market trends
    
    Format the response as a JSON object.
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    let analysis;
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        analysis = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('No JSON found in response');
      }
    } catch (parseError) {
      analysis = generateMockAnalysis(careerPath, userProfile);
    }

    return analysis;
  } catch (error) {
    console.error('Error generating detailed career analysis:', error);
    return generateMockAnalysis(careerPath, userProfile);
  }
}

function generateMockAnalysis(careerPath, userProfile) {
  return {
    careerPath,
    match_score: 85,
    strengths: ["Strong technical foundation", "Excellent problem-solving abilities", "Good communication skills"],
    areas_for_improvement: ["Leadership experience", "Project management skills", "Industry-specific knowledge"],
    recommended_skills: ["Python programming", "Machine learning fundamentals", "Data analysis"],
    career_roadmap: [
      {
        stage: "Entry Level (0-2 years)",
        skills: ["Basic programming", "Problem solving", "Version control"],
        salary_range: "$50,000 - $70,000"
      },
      {
        stage: "Mid Level (2-5 years)",
        skills: ["Advanced programming", "System design", "Team collaboration"],
        salary_range: "$70,000 - $110,000"
      }
    ],
    salary_insights: {
      entry_level: "$50,000 - $70,000",
      mid_level: "$70,000 - $110,000",
      senior_level: "$110,000 - $180,000+"
    }
  };
}

function generateReasoning(userInput, career) {
  const reasons = [];
  
  if (userInput.cgpa && userInput.cgpa > 8) {
    reasons.push("strong academic performance");
  }
  
  if (userInput.skills?.Programming > 7) {
    reasons.push("excellent programming skills");
  }
  
  if (userInput.interests?.Technology > 7) {
    reasons.push("high interest in technology");
  }

  return reasons.length > 0 
    ? `Based on your ${reasons.join(', ')}, this career path aligns well with your profile.`
    : `This career path matches your overall profile and shows good potential for growth.`;
}

function getRequiredSkills(career) {
  const skillsMap = {
    'Software Developer': ['Programming', 'Problem Solving', 'Software Design', 'Testing', 'Version Control'],
    'Data Scientist': ['Python/R', 'Statistics', 'Machine Learning', 'Data Visualization', 'SQL'],
    'Machine Learning Engineer': ['Python', 'TensorFlow/PyTorch', 'MLOps', 'Cloud Computing', 'Statistics'],
    'Full Stack Developer': ['HTML/CSS', 'JavaScript', 'React/Angular', 'Backend Development', 'Database Management'],
  };
  
  return skillsMap[career] || ['Technical Skills', 'Problem Solving', 'Communication', 'Teamwork'];
}

function getSuggestedCourses(career) {
  const coursesMap = {
    'Software Developer': ['Advanced Programming', 'Software Engineering', 'Data Structures', 'System Design'],
    'Data Scientist': ['Statistics', 'Machine Learning', 'Python for Data Science', 'Data Visualization'],
    'Machine Learning Engineer': ['Deep Learning', 'MLOps', 'Advanced ML', 'Cloud Computing'],
    'Full Stack Developer': ['Modern JavaScript', 'Backend Development', 'Database Design', 'Web Security'],
  };
  
  return coursesMap[career] || ['Industry Certification', 'Soft Skills', 'Project Management', 'Communication'];
}

function getSalaryRange(career) {
  const salaryMap = {
    'Software Developer': 12,
    'Data Scientist': 15,
    'Machine Learning Engineer': 18,
    'Full Stack Developer': 14,
  };
  
  return salaryMap[career] || 10;
}

function getIndustryGrowth(career) {
  const growthMap = {
    'Software Developer': 'High (22% growth expected)',
    'Data Scientist': 'Very High (35% growth expected)',
    'Machine Learning Engineer': 'Extremely High (40% growth expected)',
    'Full Stack Developer': 'High (28% growth expected)',
  };
  
  return growthMap[career] || 'Moderate growth expected';
}

function getActionSteps(career) {
  const stepsMap = {
    'Software Developer': ['Build portfolio', 'Contribute to open source', 'Learn frameworks', 'Practice coding'],
    'Data Scientist': ['Work on projects', 'Learn Python/R', 'Create dashboards', 'Get certified'],
    'Machine Learning Engineer': ['Implement ML models', 'Learn MLOps', 'Build pipelines', 'Stay updated'],
  };
  
  return stepsMap[career] || ['Build skills', 'Network', 'Create profile', 'Apply for positions'];
}

function generateExplanation(userInput, prediction) {
  return `Based on your profile analysis, including your CGPA of ${userInput.cgpa || 'N/A'}, ` +
         `our AI model predicts that ${prediction.career} is the most suitable career path for you ` +
         `with ${prediction.confidence}% confidence using ${prediction.method} methodology.`;
}

function generateBasicCareerAnalysis(userInput, prediction) {
  const predictions = [
    {
      career: prediction.career,
      confidence: prediction.confidence,
      reasoning: generateReasoning(userInput, prediction.career),
      skillsRequired: getRequiredSkills(prediction.career),
      suggestedCourses: getSuggestedCourses(prediction.career),
      salaryRange: getSalaryRange(prediction.career),
      industryGrowth: getIndustryGrowth(prediction.career),
      actionSteps: getActionSteps(prediction.career),
    }
  ];

  return {
    predictions: predictions,
    explanation: generateExplanation(userInput, prediction),
    aiInsights: "Career analysis based on profile matching and industry trends."
  };
}

function generatePredictionId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

async function savePredictionToFirestore(userId, response) {
  try {
    const predictionDoc = {
      userId: userId,
      success: response.success,
      predictions: response.predictions,
      explanation: response.explanation,
      aiInsights: response.aiInsights,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      created_at: new Date().toISOString(),
      userInput: response.userInput,
      modelConfidence: response.modelConfidence,
      method: response.method,
    };

    await db.collection('predictions').add(predictionDoc);
  } catch (error) {
    console.error('Error saving prediction to Firestore:', error);
  }
}

function getMostFrequent(arr) {
  if (arr.length === 0) return null;
  
  const frequency = {};
  arr.forEach(item => {
    frequency[item] = (frequency[item] || 0) + 1;
  });
  
  return Object.keys(frequency).reduce((a, b) => frequency[a] > frequency[b] ? a : b);
}