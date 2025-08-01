📘 Beginner’s Manual: Build Your First Python Dashboard App

🧩 PART 1: Install the Tools
1.1 ✅ Install Python
Visit https://www.python.org/downloads


Download the latest stable version (3.13.+)


⚠️ During installation, check the box: ✅ “Add Python to PATH”



1.2 ✅ Install VS Code (Visual Studio Code)
Download from: https://code.visualstudio.com/


Install and launch it.


Install the Python extension:


Go to Extensions (Ctrl + Shift + X)


Search for “Python” by Microsoft and click Install



1.3 (Optional) ✅ Install Anaconda (For Data Science Users)
If you plan to do more data analysis work later:
Download from: https://www.anaconda.com/products/distribution


This comes with Python, Jupyter, and many packages pre-installed.


⚠️ You do not need Anaconda for dashboard apps — regular Python + pip is enough.

1.4 ✅ Install PostgreSQL
Download from: https://www.postgresql.org/download/


During installation:


Set username: postgres


Choose a password (e.g., Admin for this tutorial)


Install pgAdmin to manage the database via GUI



🧩 PART 2: Set Up Your Project
2.1 📁 Create a Project Folder
Example:
plaintext
CopyEdit
C:\Users\YourName\Downloads\dashboard_project

Open this folder in VS Code:
mathematica
CopyEdit
File → Open Folder


2.2 🔧 (Optional) Create a Virtual Environment
Open terminal in VS Code:
bash
CopyEdit
python -m venv venv

Activate the environment:
bash
CopyEdit
venv\Scripts\activate


2.3 📦 Install Required Python Libraries
Run these commands in terminal:
bash
CopyEdit
pip install streamlit psycopg2-binary sqlalchemy plotly pandas


🧩 PART 3: Create a Simple To-Do Dashboard App
3.1 🧠 Python Code
Create a file called todo_app.py and paste the following:
python
CopyEdit
import streamlit as st
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# DB connection (use your own password if not 'Admin')
engine = create_engine("postgresql://postgres:Admin@localhost:5432/todo_app")
Base = declarative_base()

# Table definition
class Todo(Base):
    __tablename__ = 'todos'
    id = Column(Integer, primary_key=True)
    task = Column(String)
    done = Column(Boolean, default=False)

Base.metadata.create_all(engine)
Session = sessionmaker(bind=engine)
session = Session()

# Streamlit interface
st.title("✅ To-Do App")

task = st.text_input("Add a new task")
if st.button("Add Task") and task:
    new_task = Todo(task=task)
    session.add(new_task)
    session.commit()
    st.experimental_rerun()

st.subheader("Tasks")
todos = session.query(Todo).all()
for todo in todos:
    cols = st.columns([6, 1, 1])
    cols[0].write(todo.task)
    if cols[1].button("✔", key=f"done{todo.id}"):
        todo.done = True
        session.commit()
    if cols[2].button("🗑️", key=f"del{todo.id}"):
        session.delete(todo)
        session.commit()


3.2 🚀 Run the App
bash
CopyEdit
streamlit run todo_app.py

Visit http://localhost:8501 in your browser.

🧩 PART 4: Troubleshooting Tips
🔍 ModuleNotFoundError
You may be using the wrong Python version.
Check:
bash
CopyEdit
where python

or select Python interpreter in VS Code:
 Ctrl + Shift + P → "Python: Select Interpreter"

🔍 psycopg2 still not found?
Make sure it’s installed in the right environment:
bash
CopyEdit
python -m pip install psycopg2-binary


🧩 PART 5: Enhance Your Dashboard
You can later add:
📊 Plotly charts


📅 Due dates


👥 User authentication


📤 Deployment to the web (e.g., using Streamlit Cloud)



✅ Summary Checklist
Step
Task
Done?
1
Install Python
✅
2
Install VS Code
✅
3
Install PostgreSQL
✅
4
Install Python libraries
✅
5
Create dashboard app
✅
6
Run using Streamlit
✅



📈 What's Next?
You can now add:
Filters (e.g., completed vs pending tasks)


Due dates (use datetime)


Charts using Plotly (e.g., pie chart of task status)


Login using Streamlit Authenticator



📘 Appendix
Common Errors and Fixes
Error
Solution
ModuleNotFoundError
Use the correct Python environment and pip install <package>
psycopg2 not found
Install with pip install psycopg2-binary
Streamlit doesn't start
Ensure Python and Streamlit are installed, and you're in the right folder


