# app.py
import streamlit as st
import database as db
import datetime
import io # To handle binary data from file uploads

st.set_page_config(layout="centered")
st.title("Todo App with Streamlit and PostgreSQL")

# Function to combine date and time inputs into a datetime object
def combine_date_time(date_obj, time_obj):
    if date_obj and time_obj:
        return datetime.datetime.combine(date_obj, time_obj)
    return None

# --- CRUD Operations ---

# CREATE
st.header("Add New Todo")
with st.form("new_todo_form", clear_on_submit=True): # clear_on_submit to clear form after adding
    task_name = st.text_input("Task Name", max_chars=255)

    col_start, col_end = st.columns(2)
    with col_start:
        start_date = st.date_input("Start Date (Optional)", value=None, key="start_date_add")
        start_time_obj = st.time_input("Start Time (Optional)", value=None, key="start_time_add")
    with col_end:
        end_date = st.date_input("End Date (Optional)", value=None, key="end_date_add")
        end_time_obj = st.time_input("End Time (Optional)", value=None, key="end_time_add")

    details = st.text_area("Task Details (Optional)")

    uploaded_file = st.file_uploader("Upload Image/Video (Optional)", type=["jpg", "jpeg", "png", "gif", "mp4", "mov"], key="file_uploader_add")

    submitted = st.form_submit_button("Add Todo")
    if submitted:
        if task_name:
            # Combine date and time
            start_datetime = combine_date_time(start_date, start_time_obj)
            end_datetime = combine_date_time(end_date, end_time_obj)

            media_data = None
            media_filename = None
            media_mimetype = None

            if uploaded_file is not None:
                media_data = uploaded_file.read()
                media_filename = uploaded_file.name
                media_mimetype = uploaded_file.type

            new_id = db.create_todo(task_name, start_datetime, end_datetime, details, media_data, media_filename, media_mimetype)
            if new_id:
                st.success(f"Todo '{task_name}' added successfully with ID: {new_id}")
                st.experimental_rerun() # Rerun to refresh the list
            else:
                st.error("Failed to add todo. Please check your database connection or data.")
        else:
            st.warning("Task Name cannot be empty!")

st.markdown("---")

# READ & FILTERING
st.header("Current Todos")
todos_df = db.get_all_todos()

if not todos_df.empty:
    st.subheader("Filter and Search Todos")
    col_filter1, col_filter2, col_filter3 = st.columns([1, 1, 1])

    with col_filter1:
        search_task_name = st.text_input("Search by Task Name", "")
    with col_filter2:
        filter_status = st.selectbox("Filter by Status", ["All", "Pending", "In Progress", "Completed", "Cancelled"])
    with col_filter3:
        time_filter_option = st.selectbox("Time-Based Filters", ["All", "Overdue", "Upcoming (Next 7 Days)", "Completed Dates"])

    filtered_df = todos_df.copy()

    # Apply Task Name filter
    if search_task_name:
        filtered_df = filtered_df[filtered_df['task_name'].str.contains(search_task_name, case=False, na=False)]

    # Apply Status filter
    if filter_status != "All":
        filtered_df = filtered_df[filtered_df['status'] == filter_status]

    # Apply Time-Based filters
    now = datetime.datetime.now()
    if time_filter_option == "Overdue":
        # Overdue: has end_time, end_time is in the past, and status is not 'Completed'
        filtered_df = filtered_df[
            (filtered_df['end_time'].notna()) &
            (filtered_df['end_time'] < now) &
            (filtered_df['status'] != 'Completed')
        ]
    elif time_filter_option == "Upcoming (Next 7 Days)":
        # Upcoming: has start_time, start_time is in next 7 days, and status is 'Pending' or 'In Progress'
        seven_days_later = now + datetime.timedelta(days=7)
        filtered_df = filtered_df[
            (filtered_df['start_time'].notna()) &
            (filtered_df['start_time'] >= now) &
            (filtered_df['start_time'] <= seven_days_later) &
            (filtered_df['status'].isin(['Pending', 'In Progress']))
        ]
    elif time_filter_option == "Completed Dates":
        # Completed: has end_time and status is 'Completed'
        filtered_df = filtered_df[
            (filtered_df['end_time'].notna()) &
            (filtered_df['status'] == 'Completed')
        ]

    if not filtered_df.empty:
        # Remove the index column from being shown in the dashboard
        st.dataframe(filtered_df[['id', 'task_name', 'start_time', 'end_time', 'details', 'status']], hide_index=True, use_container_width=True)

        st.markdown("---")
        st.header("Update or Delete Todo")

        # Create display options for the selectbox
        # Use a descriptive string for better UX when selecting
        display_options = [f"ID: {row['id']} - {row['task_name']} ({row['status']})" for index, row in filtered_df.iterrows()]
        
        # If there are options, allow selection
        if display_options:
            selected_display_option = st.selectbox("Select Todo to Update/Delete", display_options, key="select_todo_edit_delete")

            # Extract the ID from the selected display string
            selected_todo_id = int(selected_display_option.split(" - ")[0].replace("ID: ", ""))
            
            # Fetch the full data for the selected todo
            todo_data = db.get_todo_by_id(selected_todo_id)

            if todo_data:
                # todo_data is a tuple, convert to dictionary for easier access
                # Ensure the order of columns matches get_todo_by_id in database.py
                columns = ['id', 'task_name', 'start_time', 'end_time', 'details', 'status', 'media_data', 'media_filename', 'media_mimetype']
                todo_dict = dict(zip(columns, todo_data))

                with st.form(f"edit_todo_form_{selected_todo_id}"):
                    st.subheader(f"Editing Todo ID: {selected_todo_id}")
                    edit_task_name = st.text_input("Task Name", value=todo_dict['task_name'], key=f"edit_task_name_{selected_todo_id}")

                    col_edit_start, col_edit_end = st.columns(2)
                    with col_edit_start:
                        # Convert existing timestamp to date and time objects for st.date_input and st.time_input
                        edit_start_date = todo_dict['start_time'].date() if todo_dict['start_time'] else None
                        edit_start_time_obj = todo_dict['start_time'].time() if todo_dict['start_time'] else None
                        edit_start_date = st.date_input("Start Date", value=edit_start_date, key=f"edit_start_date_{selected_todo_id}")
                        edit_start_time_obj = st.time_input("Start Time", value=edit_start_time_obj, key=f"edit_start_time_{selected_todo_id}")
                    with col_edit_end:
                        edit_end_date = todo_dict['end_time'].date() if todo_dict['end_time'] else None
                        edit_end_time_obj = todo_dict['end_time'].time() if todo_dict['end_time'] else None
                        edit_end_date = st.date_input("End Date", value=edit_end_date, key=f"edit_end_date_{selected_todo_id}")
                        edit_end_time_obj = st.time_input("End Time", value=edit_end_time_obj, key=f"edit_end_time_{selected_todo_id}")

                    edit_details = st.text_area("Task Details", value=todo_dict['details'], key=f"edit_details_{selected_todo_id}")
                    status_options = ['Pending', 'In Progress', 'Completed', 'Cancelled']
                    edit_status = st.selectbox("Status", options=status_options, index=status_options.index(todo_dict['status']), key=f"edit_status_{selected_todo_id}")

                    # Display existing media if any
                    if todo_dict['media_data']:
                        st.subheader("Current Attached Media:")
                        if todo_dict['media_mimetype'].startswith('image/'):
                            st.image(io.BytesIO(todo_dict['media_data']), caption=todo_dict['media_filename'], use_column_width=True)
                        elif todo_dict['media_mimetype'].startswith('video/'):
                            st.video(io.BytesIO(todo_dict['media_data']), format=todo_dict['media_mimetype'])
                        st.checkbox("Remove current media", key=f"remove_media_{selected_todo_id}")

                    uploaded_file_edit = st.file_uploader("Upload New Image/Video (Optional)", type=["jpg", "jpeg", "png", "gif", "mp4", "mov"], key=f"file_uploader_edit_{selected_todo_id}")

                    col1, col2 = st.columns(2)
                    with col1:
                        update_button = st.form_submit_button("Update Todo")
                    with col2:
                        delete_button = st.form_submit_button("Delete Todo")

                    if update_button:
                        if edit_task_name:
                            # Combine date and time for update
                            edit_start_datetime = combine_date_time(edit_start_date, edit_start_time_obj)
                            edit_end_datetime = combine_date_time(edit_end_date, edit_end_time_obj)

                            current_media_data = todo_dict['media_data']
                            current_media_filename = todo_dict['media_filename']
                            current_media_mimetype = todo_dict['media_mimetype']

                            if st.session_state.get(f"remove_media_{selected_todo_id}", False):
                                current_media_data = None
                                current_media_filename = None
                                current_media_mimetype = None
                            
                            # If a new file is uploaded, use it
                            if uploaded_file_edit is not None:
                                current_media_data = uploaded_file_edit.read()
                                current_media_filename = uploaded_file_edit.name
                                current_media_mimetype = uploaded_file_edit.type

                            if db.update_todo(selected_todo_id, edit_task_name, edit_start_datetime, edit_end_datetime,
                                              edit_details, edit_status, current_media_data, current_media_filename, current_media_mimetype):
                                st.success(f"Todo ID {selected_todo_id} updated successfully!")
                                st.experimental_rerun() # Rerun to refresh the list
                            else:
                                st.error("Failed to update todo.")
                        else:
                            st.warning("Task Name cannot be empty!")

                    if delete_button:
                        # Add a confirmation step for deletion
                        st.info("Click 'Confirm Delete' below if you are sure.")
                        confirm_delete = st.button("Confirm Delete", key=f"confirm_delete_{selected_todo_id}")
                        if confirm_delete:
                            if db.delete_todo(selected_todo_id):
                                st.success(f"Todo ID {selected_todo_id} deleted successfully!")
                                st.experimental_rerun() # Rerun to refresh the list
                            else:
                                st.error("Failed to delete todo.")
            else:
                st.error("Todo not found for the selected ID.")
        else:
            st.info("No todos match the current filter/search criteria.")
    else:
        st.info("No todos found. Add a new todo above or adjust filters!")
