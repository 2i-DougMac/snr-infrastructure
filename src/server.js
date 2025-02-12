// A Lovely Horse Application
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>My Lovely Horse</title>
        <script>
          const lines = [
            "(My lovely, lovely, lovely horse)",
            "My lovely horse (My lovely horse)",
            "Running through the fields (Running through the fields)",
            "Where are you going",
            "With your fetlocks blowing",
            "In the wind? (All summer)",
            "I want to shower you with sugar lumps",
            "And ride you over fences",
            "Polish your hooves every single day",
            "And bring you to the horse dentist",
            "(My lovely, lovely, lovely horse)",
            "My lovely horse (My lovely horse)",
            "You're a pony no more (You're a pony no more)",
            "Running around",
            "With a man on your back (But...)",
            "Like a train in the night, yeah (...I love you anyway)",
            "Like a train in the night",
            "(My lovely, lovely, lovely horse)"
          ];

          let currentLine = 0;
          
          // Add the next line from the array and increment the line
          function showLine() {
            if (currentLine < lines.length) {
              const newLine = document.createElement('p');
              newLine.innerText = lines[currentLine];
              document.getElementById('lineContainer').appendChild(newLine);
              currentLine++;
            }
          }
        </script>
      </head>
      <body onclick="showLine()">
        <h1>My Lovely Horse</h1>
        <!-- Container where the lines will be appended -->
        <div id="lineContainer"></div>
      </body>
    </html>
  `);
});

app.listen(3000, function () {
  console.log("app listening on port 3000");
});
