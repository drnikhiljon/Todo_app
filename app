# app.py
import streamlit as st
import database as db # Import your database functions
import datetime

st.set_page_config(layout="wide")
st.title("Simple Todo App with Streamlit and PostgreSQL")

# --- CRUD Operations ---

# CREATE
st.header("Add New Todo")
with st.form("new_todo_form"):
    task_name = st.text_input("Task Name", max_chars=255)
    start_time = st.date_input("Start Date (Optional)", value=None)
    end_time = st.date_input("End Date (Optional)", value=None)
    details = st.text_area("Task Details (Optional)")

    submitted = st.form_submit_button("Add Todo")
    if submitted:
        if task_name:
            # Convert date objects to datetime for timestamp compatibility
            start_dt = datetime.datetime.combine(start_time, datetime.time.min) if start_time else None
            end_dt = datetime.datetime.combine(end_time, datetime.time.max) if end_time else None # Use max time for end date

            new_id = db.create_todo(task_name, start_dt, end_dt, details)
            if new_id:
                st.success(f"Todo '{task_name}' added successfully with ID: {new_id}")
            else:
                st.error("Failed to add todo. Please check your database connection.")
        else:
            st.warning("Task Name cannot be empty!")

st.markdown("---")

# READ
st.header("Current Todos")
todos_df = db.get_all_todos()

if not todos_df.empty:
    st.dataframe(todos_df, use_container_width=True)

    # UPDATE & DELETE Section
    st.header("Update or Delete Todo")
    todo_ids = todos_df['id'].tolist()
    selected_todo_id = st.selectbox("Select Todo ID to Update/Delete", todo_ids)

    if selected_todo_id:
        todo_data = db.get_todo_by_id(selected_todo_id)
        if todo_data:
            # todo_data is a tuple, convert to dictionary for easier access
            columns = ['id', 'task_name', 'start_time', 'end_time', 'details', 'status']
            todo_dict = dict(zip(columns, todo_data))

            with st.form(f"edit_todo_form_{selected_todo_id}"):
                st.subheader(f"Editing Todo ID: {selected_todo_id}")
                edit_task_name = st.text_input("Task Name", value=todo_dict['task_name'], key=f"edit_task_name_{selected_todo_id}")

                # Convert existing timestamp to date object for st.date_input
                edit_start_date = todo_dict['start_time'].date() if todo_dict['start_time'] else None
                edit_end_date = todo_dict['end_time'].date() if todo_dict['end_time'] else None

                edit_start_time = st.date_input("Start Date", value=edit_start_date, key=f"edit_start_time_{selected_todo_id}")
                edit_end_time = st.date_input("End Date", value=edit_end_date, key=f"edit_end_time_{selected_todo_id}")

                edit_details = st.text_area("Task Details", value=todo_dict['details'], key=f"edit_details_{selected_todo_id}")
                status_options = ['Pending', 'In Progress', 'Completed', 'Cancelled']
                edit_status = st.selectbox("Status", options=status_options, index=status_options.index(todo_dict['status']), key=f"edit_status_{selected_todo_id}")

                col1, col2 = st.columns(2)
                with col1:
                    update_button = st.form_submit_button("Update Todo")
                with col2:
                    delete_button = st.form_submit_button("Delete Todo")

                if update_button:
                    if edit_task_name:
                        # Convert date objects back to datetime for update
                        edit_start_dt = datetime.datetime.combine(edit_start_time, datetime.time.min) if edit_start_time else None
                        edit_end_dt = datetime.datetime.combine(edit_end_time, datetime.time.max) if edit_end_time else None

                        if db.update_todo(selected_todo_id, edit_task_name, edit_start_dt, edit_end_dt, edit_details, edit_status):
                            st.success(f"Todo ID {selected_todo_id} updated successfully!")
                            st.experimental_rerun() # Rerun to refresh the list
                        else:
                            st.error("Failed to update todo.")
                    else:
                        st.warning("Task Name cannot be empty!")

                if delete_button:
                    if st.warning("Are you sure you want to delete this todo?"):
                        if db.delete_todo(selected_todo_id):
                            st.success(f"Todo ID {selected_todo_id} deleted successfully!")
                            st.experimental_rerun() # Rerun to refresh the list
                        else:
                            st.error("Failed to delete todo.")
        else:
            st.error("Todo not found.")
else:
    st.info("No todos found. Add a new todo above!")
