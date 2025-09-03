
# MentionAi-Auto-Bot

![MentionAi-Auto-Bit Banner](https://img.shields.io/badge/MentionAi--Auto--Bit-v1.0-blueviolet)
![Ruby](https://img.shields.io/badge/Ruby-3.0%2B-CC342D)
![License](https://img.shields.io/badge/License-MIT-green)

**MentionAi-Auto-Bit** is a Ruby-based automation script designed to interact with the Mention Network API. It fetches random questions, generates AI responses using a backend API, logs interactions, and saves the results to local files. This tool is ideal for automating question-and-answer workflows, leveraging AI to provide responses, and submitting interactions to the Mention Network platform.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [File Structure](#file-structure)
- [Error Handling](#error-handling)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Features

- **Automated Question Fetching**: Retrieves up to 15 random questions from the Mention Network API.
- **AI Response Generation**: Uses a backend API to generate responses for fetched questions.
- **Interaction Logging**: Submits question-response pairs to the Mention Network for record-keeping.
- **File Storage**: Saves questions and responses to local files (`questions.txt` and `response.txt`).
- **Retry Mechanism**: Handles API rate limits with exponential backoff (up to 3 retries).
- **User-Friendly Interface**: Displays a colorful CLI with a countdown timer and progress indicators.
- **Configurable Cycles**: Allows users to specify the number of automation cycles.
- **Error Handling**: Robust error handling with retry logic and graceful exit on interrupts.
- **Environment-Based Configuration**: Uses a `.env` file for secure storage of API credentials.

---

## Prerequisites

Before running the script, ensure you have the following:

- **Ruby**: Version 3.0 or higher installed. Check with `ruby --version`.
- **Git**: For cloning the repository.
- **Dependencies**: The script requires the following Ruby gems:
  - `net/http` (standard library)
  - `uri` (standard library)
  - `json` (standard library)
  - `dotenv` (`gem install dotenv`)
  - `colorize` (`gem install colorize`)
  - `io/console` (standard library)
- **API Access**:
  - A valid `AUTH_TOKEN` for the Mention Network API.
  - A `USER_ID` for logging interactions.
- **Internet Connection**: Required for API communication.

---

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/CryptoExplor/MentionAi-Auto-Bot.git
   cd MentionAi-Auto-Bot
   ```

2. **Install Ruby Gems**:
   Run the following command to install required dependencies:
   ```bash
   gem install dotenv colorize
   ```
![Screenshot_2025-09-02-11-35-19-42_4d38fce200f96aeac5e860e739312e76](https://github.com/user-attachments/assets/f4a8ddfb-36b9-4454-9f09-1388dbddf36a)

![Screenshot_2025-09-02-11-35-39-07_4d38fce200f96aeac5e860e739312e76](https://github.com/user-attachments/assets/c3c9f4ac-f644-492e-8f26-068a417e95c5)


3. **Set Up Environment Variables**:
   Create a `.env` file in the project root and add your API credentials:
   ```env
   AUTH_TOKEN=your_mention_network_auth_token
   USER_ID=your_user_id
   ```
   Replace `your_mention_network_auth_token` and `your_user_id` with your actual credentials.

4. **Verify Ruby Installation**:
   Ensure Ruby is installed:
   ```bash
   ruby --version
   ```

---

## Configuration

The script is configured via environment variables and constants defined at the top of the script:

- **Environment Variables** (in `.env`):
  - `AUTH_TOKEN`: Your Mention Network API token.
  - `USER_ID`: Your user ID for interaction logging.
- **Constants** (in `mentionai-auto-bit.rb`):
  - `BASE_URL`: Mention Network API endpoint (`https://api.mention.network`).
  - `BACKEND_API_URL`: Backend API for AI response generation.
  - `MAX_QUESTIONS`: Maximum number of questions to fetch per cycle (default: 15).
  - `MAX_RETRIES`: Maximum retry attempts for API rate limits (default: 3).
  - `RETRY_DELAY_BASE`: Base delay for retries (default: 10 seconds).
  - `DELAY_BETWEEN_CYCLES`: Delay between cycles (default: 10 seconds).
  - `WAIT_TIME_HOURS`: Wait time between full runs (default: 24 hours).

Modify these constants in the script if needed, but the defaults are optimized for general use.

---

## Usage

1. **Run the Script**:
   ```bash
   ruby main.rb
   ```

2. **Input the Number of Cycles**:
   When prompted, enter the number of cycles (e.g., `10`) to perform. Each cycle:
   - Fetches questions.
   - Generates AI responses.
   - Saves questions and responses to files.
   - Submits interactions to the Mention Network API.

3. **Monitor Progress**:
   The script displays a colorful CLI with:
   - A banner at startup.
   - Progress spinners for fetching, generating, and submitting.
   - Truncated question and response previews.
   - A countdown timer for the wait period between runs (default: 24 hours).

4. **Stop the Script**:
   Press `Ctrl+C` to interrupt the script gracefully.

---

## How It Works

1. **Initialization**:
   - Loads environment variables (`AUTH_TOKEN`, `USER_ID`) from the `.env` file.
   - Displays a magenta-colored banner with the project name.

2. **Cycle Execution**:
   - Prompts the user for the number of cycles.
   - For each cycle:
     - **Fetches Questions**: Retrieves up to 15 random questions from the Mention Network API.
     - **Saves Questions**: Writes questions to `questions.txt`.
     - **Generates Responses**: Sends each question to the backend AI API and collects responses.
     - **Saves Responses**: Writes responses to `response.txt`.
     - **Searches AI Model**: Queries the Mention Network API for the `gpt-3-5` model ID.
     - **Submits Interactions**: Logs question-response pairs to the Mention Network API.
   - Waits 10 seconds between cycles.

3. **Long Wait**:
   - After completing all cycles, waits 24 hours (configurable) before restarting.

4. **Error Handling**:
   - Retries on API rate limits (HTTP 429) with exponential backoff.
   - Retries failed cycles after 20 seconds.
   - Exits gracefully on `Ctrl+C` or fatal errors.

---

## File Structure

```plaintext
MentionAi-Auto-Bit/
├── main.rb                # Main Ruby script
├── .env                   # Environment variables (create manually)
├── questions.txt          # Output file for fetched questions
├── response.txt           # Output file for AI-generated responses
├── README.md              # This file
```

- **`mentionai-auto-bit.rb`**: The core script that handles all automation tasks.
- **`.env`**: Stores sensitive API credentials (not tracked by Git).
- **`questions.txt`**: Stores fetched questions, updated each cycle.
- **`response.txt`**: Stores AI-generated responses, updated each cycle.

---

## Error Handling

The script includes robust error handling:

- **Missing Credentials**: Exits if `AUTH_TOKEN` or `USER_ID` is missing in `.env`.
- **API Rate Limits**: Retries up to 3 times with exponential backoff (10s, 20s, 40s).
- **File I/O Errors**: Reports errors when reading/writing `questions.txt` or `response.txt`.
- **API Failures**: Logs errors for failed API requests and skips invalid interactions.
- **User Interrupt**: Handles `Ctrl+C` with a graceful exit message.
- **General Errors**: Displays detailed error messages and backtraces for debugging.

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Make your changes and commit (`git commit -m "Add your feature"`).
4. Push to your branch (`git push origin feature/your-feature`).
5. Open a Pull Request on GitHub.

Please ensure your code follows Ruby best practices and includes appropriate comments.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contact

For questions, issues, or suggestions, please:

- Open an issue on the [GitHub repository](https://github.com/thekazuha787/MentionAi-Auto-Bot).
- Contact the maintainer: [Your Name/Email] (replace with your contact info if desired).

Built with 💜 by [thekazuha787](https://github.com/thekazuha787).

---

This README provides a clear, professional, and comprehensive guide to your project. To upload it to your GitHub repository:

1. **Create the README File**:
   - Copy the above Markdown content into a file named `README.md` in your project directory (`MentionAi-Auto-Bit/`).

2. **Add to Git**:
   ```bash
   git add README.md
   ```

3. **Commit the Changes**:
   ```bash
   git commit -m "Add detailed README.md"
   ```

4. **Push to GitHub**:
   ```bash
   git push origin main
   ```

5. **Verify on GitHub**:
   - Visit `https://github.com/thekazuha787/MentionAi-Auto-Bot` to confirm the README is displayed correctly.

If you need any tweaks or additional sections in the README, let me know!
