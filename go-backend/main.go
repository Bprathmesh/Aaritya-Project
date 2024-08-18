package main

import (
    "encoding/json"
    "log"
    "net/http"
    

    "github.com/gorilla/mux"
)

type Question struct {
    ID      int      `json:"id"`
    Text    string   `json:"text"`
    Options []string `json:"options"`
    Answer  int      `json:"answer"`
    Hint    string   `json:"hint"`
    ImageURL string  `json:"imageUrl"`
}

type Quiz struct {
    Questions []Question `json:"questions"`
}

var quiz = Quiz{
    Questions: []Question{
        {
            ID: 1, 
            Text: "What is the capital of France?", 
            Options: []string{"London", "Berlin", "Paris", "Madrid"}, 
            Answer: 2,
            Hint: "This city is known as the 'City of Light'",
            ImageURL: "/images/eiffel-tower.jpg",
        },
        {
            ID: 2, 
            Text: "Which planet is known as the Red Planet?", 
            Options: []string{"Venus", "Mars", "Jupiter", "Saturn"}, 
            Answer: 1,
            Hint: "It's named after the Roman god of war",
            ImageURL: "/images/mars.jpg",
        },
        {
            ID: 3, 
            Text: "What is the largest mammal?", 
            Options: []string{"Elephant", "Blue Whale", "Giraffe", "Hippopotamus"}, 
            Answer: 1,
            Hint: "This animal lives in the ocean",
            ImageURL: "/images/blue-whale.jpg",
        },
        {
            ID: 4, 
            Text: "Who painted the Mona Lisa?", 
            Options: []string{"Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"}, 
            Answer: 2,
            Hint: "This artist was also famous for his inventions",
            ImageURL: "/images/mona-lisa.jpg",
        },
        {
            ID: 5, 
            Text: "What is the chemical symbol for gold?", 
            Options: []string{"Go", "Gd", "Au", "Ag"}, 
            Answer: 2,
            Hint: "It's derived from the Latin word 'aurum'",
            ImageURL: "/images/gold.jpg",
        },
        {
            ID: 6, 
            Text: "Which country is home to the kangaroo?", 
            Options: []string{"New Zealand", "South Africa", "Australia", "Brazil"}, 
            Answer: 2,
            Hint: "This country is both a continent and an island",
            ImageURL: "/images/kangaroo.jpg",
        },
        {
            ID: 7, 
            Text: "What is the largest planet in our solar system?", 
            Options: []string{"Earth", "Mars", "Jupiter", "Saturn"}, 
            Answer: 2,
            Hint: "This planet is named after the king of the Roman gods",
            ImageURL: "/images/jupiter.jpg",
        },
    },
}

func getQuiz(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(quiz)
}

func main() {
    router := mux.NewRouter()

    // Serve the quiz API
    router.HandleFunc("/api/quiz", getQuiz).Methods("GET")

    // Serve static files (images)
    fs := http.FileServer(http.Dir("./images"))
    router.PathPrefix("/images/").Handler(http.StripPrefix("/images/", fs))

    // Enable CORS
    router.Use(corsMiddleware)

    log.Println("Server is running on http://localhost:8080")
    log.Fatal(http.ListenAndServe(":8080", router))
}

func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}