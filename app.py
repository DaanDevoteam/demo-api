from flask import Flask, jsonify, request
import datetime
import os

app = Flask(__name__)

# Store some demo data
tasks = [
    {"id": 1, "title": "Learn Azure", "completed": False},
    {"id": 2, "title": "Build API", "completed": False}
]

@app.route('/')
def home():
    return jsonify({
        "message": "Demo API is running",
        "version": "1.0.0",
        "timestamp": datetime.datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.datetime.utcnow().isoformat()
    })

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    return jsonify({"tasks": tasks})

@app.route('/api/tasks', methods=['POST'])
def create_task():
    data = request.get_json()
    new_task = {
        "id": len(tasks) + 1,
        "title": data.get('title', 'Untitled'),
        "completed": False
    }
    tasks.append(new_task)
    return jsonify(new_task), 201

@app.route('/api/tasks/<int:task_id>', methods=['GET'])
def get_task(task_id):
    task = next((t for t in tasks if t['id'] == task_id), None)
    if task:
        return jsonify(task)
    return jsonify({"error": "Task not found"}), 404

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)