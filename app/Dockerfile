# Use an official Node.js runtime as a parent image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install dependencies
RUN npm install

# Make the container's port 8080 available to the outside
EXPOSE 8080

# Run the app
CMD [ "node", "app.js" ]
