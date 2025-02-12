# Specify the Base Image on which to build.
# (FROM is the first command of a Dockerfile)
FROM node:23-alpine3.20

# Copy the package.json && package-lock.json
# as well as the application directory with
# '/' at the end of '/user/app' used so that Docker
# will create the directory if it doesn't exist.
COPY src /usr/app/
COPY package.json /usr/app/
COPY package-lock.json /usr/app/

# WORKDIR is like cd - it changes the directory
# from which the next command will be executed.
WORKDIR /usr/app

# Install the application dependencies.
RUN npm install

# Set a port number to expose the application
EXPOSE 3000

# Define the container startup command.
# (CMD is the last command of a Dockerfile)
CMD ["node", "server.js"]
