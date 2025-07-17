local M = {}

M.render = {
	["basic.http"] = [[
### Basic GET Request
GET https://jsonplaceholder.typicode.com/posts/1
Content-Type: application/json

###

### Basic POST Request
POST https://jsonplaceholder.typicode.com/posts
Content-Type: application/json

{
  "title": "foo",
  "body": "bar", 
  "userId": 1
}

###

### Basic PUT Request
PUT https://jsonplaceholder.typicode.com/posts/1
Content-Type: application/json

{
  "id": 1,
  "title": "updated title",
  "body": "updated body",
  "userId": 1
}

###

### Basic DELETE Request
DELETE https://jsonplaceholder.typicode.com/posts/1
]],

	["auth.http"] = [[
### Bearer Token Authentication
GET https://api.example.com/protected
Authorization: Bearer {{token}}
Content-Type: application/json

###

### Basic Authentication
GET https://api.example.com/basic-auth
Authorization: Basic {{base64(username:password)}}

###

### API Key Authentication
GET https://api.example.com/data
X-API-Key: {{api_key}}
Content-Type: application/json

###

### OAuth 2.0 Example
POST https://oauth.example.com/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id={{client_id}}&client_secret={{client_secret}}
]],

	["crud.http"] = [[
### Create Resource
POST https://api.example.com/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30
}

###

### Read Resource
GET https://api.example.com/users/1
Accept: application/json

###

### Update Resource
PUT https://api.example.com/users/1
Content-Type: application/json

{
  "name": "John Smith",
  "email": "johnsmith@example.com",
  "age": 31
}

###

### Partial Update
PATCH https://api.example.com/users/1
Content-Type: application/json

{
  "email": "newemail@example.com"
}

###

### Delete Resource
DELETE https://api.example.com/users/1

###

### List Resources with Pagination
GET https://api.example.com/users?page=1&limit=10
Accept: application/json
]],

	["environment.http"] = [[
### Development Environment
# @name dev_request
GET {{base_url}}/api/health
Authorization: Bearer {{dev_token}}
Content-Type: application/json

###

### Staging Environment  
# @name staging_request
GET {{staging_url}}/api/health
Authorization: Bearer {{staging_token}}
Content-Type: application/json

###

### Production Environment
# @name prod_request
GET {{prod_url}}/api/health
Authorization: Bearer {{prod_token}}
Content-Type: application/json

###

### Environment Variables Example
GET {{base_url}}/api/users/{{user_id}}
Authorization: Bearer {{token}}
X-Request-ID: {{$uuid}}

# @lang=lua
> {%
-- Post-request script
local response_data = vim.json.decode(response.body)
-- Save token for next requests
client.global.set("user_token", response_data.token)
%}
]],
}

return M
