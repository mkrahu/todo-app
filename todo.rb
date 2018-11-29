require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'sinatra/content_for'
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret' # don't do this in a regular app
end

helpers do
  def complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if complete?(list)
  end

  def uncompleted_todos(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def total_todos(list)
    list[:todos].size
  end

  def sorted_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sorted_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all of the lists
get '/lists' do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list
end

# Return error message if name is invalid. Return nil if name is valid.
def error_in_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique'
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip

  error = error_in_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'

    redirect '/lists'
  end
end

# Display an individual list
get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Edit am existing list
get '/lists/:index/edit' do
  index = params[:index].to_i
  @list = session[:lists][index]

  erb :edit_list, layout: :layout
end

# Edit an existing list
post '/lists/:index' do
  index = params[:index].to_i
  @list = session[:lists][index]

  list_name = params[:list_name].strip

  error = error_in_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][index][:name] = list_name
    session[:success] = 'The list has been updated.'

    redirect "lists/#{index}"
  end
end

# Delete an existing list
post '/lists/:index/destroy' do
  index = params[:index].to_i

  session[:lists].delete_at(index)

  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Return error message if todo is invalid. Return nil if todo is valid.
def error_in_todo(name)
  if !(1..100).cover?(name.size)
    'Todo name must be between 1 and 100 characters.'
  end
end

# Add a todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo = params[:todo].strip

  error = error_in_todo(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = 'The todo has been added.'

    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:list_id/todos/:todo_id/destroy' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  todo_id = params[:todo_id].to_i

  list[:todos].delete_at(todo_id)
  session[:success] = "Todo successfully deleted."

  redirect "/lists/#{list_id}"
end

# Update status of todo in a list
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  is_completed = params[:completed] == "true"

  todo_id = params[:todo_id].to_i

  @list[:todos][todo_id][:completed] = is_completed

  redirect "/lists/#{@list_id}"
end

# Complete all todos in a list
post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."

  redirect "/lists/#{@list_id}"
end
