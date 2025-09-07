from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f"Hello from the Flask app in the {os.environ.get('ENVIRONMENT', 'unknown')} environment!"

if __name__ == '__main__":
    # In a real app, you'd connect to the database here
    # For this example, we're just demonstrating the app
    app.run(host='0.0.0.0', port=80)