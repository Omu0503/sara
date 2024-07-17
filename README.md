# S.A.R.A. - Smart Automated Routing Assistant

S.A.R.A. is a sophisticated navigation AI assistant whereby users can speak to the app when they face confusions while navigating their route. It's like having a partner riding alongside you, who completely knows your route and who you can speak to and ask for their guidance at any point of confusion on your route.
This project leverages various technologies to enhance the navigation experience, including Flutter, OpenCV, Python, Google Cloud services, and OpenAI APIs.


## Features

- **Lane Guidance**: Onw of the major problems users reported in our survey was that not sufficient information was given when approaching an exit/turn/diversion. For this reason, a comprehensive lane guidance system was developed whereby users would receive verbal instructions that contained contextual information (for eg. Do you see the bridge ahead? take the right just after) and by indicating the lanes (for eg. Stay on the second most right lane for the upcoming diversion).
- **Contextual Data**: Users could ask for any nearby petrol stations or shopping malls, and the app would direct you there. And yes, you just have to speak to it and she will respond and guide you!
- **Traffic Information**: The app also updates users with the latest traffic information, such as road closures, accidents, etc, on the route.

## Technologies Used

- **Flutter**: Frontend framework for building the mobile application.
- **Lane Detection Algorithm**: The app streams the video of the road ahead. This implies that the user's phone should be placed at an angle that is able to record the road ahead clearly. Computer vision library openCV was used to implement a lane detection algorithm. An open-source algortihm was used. You can find the github of its code <a href="https://github.com/cfzd/Ultra-Fast-Lane-Detection-v2">here</a>. This algorithm was made into an API using **flask** that would emit a JSON response containing the number of lanes on the road and the the lane on which the user is currently on.
- **Microsoft AWS**: The flask API was hoisted on a Microsoft AWS server in Singapore.
- **WakeWord Detection software**: A wakeword detection model was used to "awaken" the app to start listening. The users have to call out 'hey Sara!' in order for it to start listening. Users could also call out out 'Saarah' 'Saraa', 'Saaraa' to awaken it. The model used was an open source implementation of <a href="https://github.com/dscripka/openWakeWord">this</a>.
- **Google Cloud Services**: Various Google maps APIs were used such as roads nearby, places nearby, google maps sdk, and routes API.
- **OpenAI APIs**: The novelty of the app lies in the fine-tuned gpt 3.5 turbo model trained on around 150 sample conversations. 150 may sound less but it was ideal for the model to generate responses with nuances but also stick to the pattern it was trained on. Other services of OpenAI implemented was their text-to-speech model.
  

## Overview os the System Architecture

### 1. App (Main Interface)
- **Video (Driver’s Perspective)**: The app captures real-time video from the driver’s perspective, which is essential for lane detection and other visual processing tasks.
- **Audio (User’s Command)**: The app listens for voice commands from the user, which are processed for navigation and other functions.
- **Destination**: The app allows users to set their destination, which is a crucial input for generating routes and guidance.

### 2. Video Processing
- **Lane Detection Algorithm**: This component processes the video feed to detect lanes on the road. It helps in providing real-time lane guidance to the user.

### 3. NLP1 (Natural Language Processing 1)
- **Wake Word Model**: This model listens for a specific wake word to activate the app’s voice command functionality.
- **Speech to Text**: Converts the user’s spoken commands into text for further processing.
- **Query Classification (NLP)**: Classifies the text commands into different categories such as route requests, traffic information, etc., to understand the user’s intent.

### 4. Algorithm
- **Fine-tuned LLM (Language Model)**: This model is fine-t tuned for the specific needs of the S.A.R.A. app. It processes the classified queries and generates appropriate responses or actions.

### 5. API Calls
- **Google Maps Routes API**: Fetches route information based on the user’s destination and current location.
- **Roads Nearby**: Provides information about nearby roads, which can be useful for rerouting or providing additional context to the user.
- **Other APIs**: These could include APIs for traffic information, weather updates, points of interest, etc.
- **API Responses**: The responses from these API calls are used to provide real-time information and updates to the user.

### 6. NLP2 (Natural Language Processing 2)
- **Text to Speech**: Converts the generated responses from the Fine-tuned LLM into speech, allowing the app to communicate with the user audibly.
## User-flow

The app beigns with the homepage showing the users current location and a search button to look up for their destination.

<p align="center" style="margin-top:40px; margin-bottom:40px;"><img src="readMeAssets/maps_ui.JPG" alt="Home Page" width="300"/></p>


On clicking the search button, the user is directed to the search page, where the user can look up for the destination of their choice. On selecting their destination, they are rfedirected to the home page where the whole route is showd on the map along with its synopsis.

On clicking 'Go', the user is directed to the navigation UI, where turn by turn virsual and auditory instrcutuins are provided. Until here, the UI is pretty much the same as other popular navigation apps. The reason for such a UI was opted because users are now comfortable with such an interface, so deviating from it wouldn't make sense.


  

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/sara-navigation-assistant.git
