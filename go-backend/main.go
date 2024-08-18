package main

import (
    "encoding/json"
    "log"
    "net/http"
    "fmt"
    "os"
    "path/filepath"

    "github.com/gorilla/mux"
)

type Question struct {
    ID       int      `json:"id"`
    Text     string   `json:"text"`
    Options  []string `json:"options"`
    Answer   int      `json:"answer"`
    Hint     string   `json:"hint"`
    ImageURL string   `json:"imageUrl"`
}

type Quiz struct {
    Questions []Question `json:"questions"`
}

var quiz = Quiz{
    Questions: []Question{
        {
            ID:       1,
            Text:     "What is the capital of France?",
            Options:  []string{"London", "Berlin", "Paris", "Madrid"},
            Answer:   2,
            Hint:     "This city is known as the 'City of Light'",
            ImageURL: "/images/eiffel-tower.jpg",
        },
        {
            ID:       2,
            Text:     "Which planet is known as the Red Planet?",
            Options:  []string{"Venus", "Mars", "Jupiter", "Saturn"},
            Answer:   1,
            Hint:     "It's named after the Roman god of war",
            ImageURL: "/images/mars.jpg",
        },
        {
            ID:       3,
            Text:     "What is the largest mammal?",
            Options:  []string{"Elephant", "Blue Whale", "Giraffe", "Hippopotamus"},
            Answer:   1,
            Hint:     "This animal lives in the ocean",
            ImageURL: "/images/blue-whale.jpg",
        },
        {
            ID:       4,
            Text:     "Who painted the Mona Lisa?",
            Options:  []string{"Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"},
            Answer:   2,
            Hint:     "This artist was also famous for his inventions",
            ImageURL: "/images/mona-lisa.jpg",
        },
        {
            ID:       5,
            Text:     "What is the chemical symbol for gold?",
            Options:  []string{"Go", "Gd", "Au", "Ag"},
            Answer:   2,
            Hint:     "It's derived from the Latin word 'aurum'",
            ImageURL: "/images/gold.jpg",
        },
        {
            ID:       6,
            Text:     "Which country is home to the kangaroo?",
            Options:  []string{"New Zealand", "South Africa", "Australia", "Brazil"},
            Answer:   2,
            Hint:     "This country is both a continent and an island",
            ImageURL: "/images/kangaroo.jpg",
        },
        {
            ID:       7,
            Text:     "What is the largest planet in our solar system?",
            Options:  []string{"Earth", "Mars", "Jupiter", "Saturn"},
            Answer:   2,
            Hint:     "This planet is named after the king of the Roman gods",
            ImageURL: "/images/jupiter.jpg",
        },
    },
}

func getQuiz(w http.ResponseWriter, r *http.Request) {
    baseURL := "http://localhost:8080"  // Change this to your actual server address when deploying
    quizCopy := quiz
    for i := range quizCopy.Questions {
        if quizCopy.Questions[i].ImageURL != "" && quizCopy.Questions[i].ImageURL[0] == '/' {
            quizCopy.Questions[i].ImageURL = baseURL + quizCopy.Questions[i].ImageURL
        }
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(quizCopy)
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

func main() {
    router := mux.NewRouter()

    // Serve the quiz API
    router.HandleFunc("/api/quiz", getQuiz).Methods("GET")

    // Serve static files (images)
    workDir, _ := os.Getwd()
    imagesDir := filepath.Join(workDir, "images")
    fileServer := http.FileServer(http.Dir(imagesDir))
    router.PathPrefix("/images/").Handler(http.StripPrefix("/images/", fileServer))

    
    router.Use(corsMiddleware)

    
    port := ":8080"
    fmt.Printf("Server is running on http://localhost%s\n", port)
    log.Printf("Serving images from: %s\n", imagesDir)
    log.Fatal(http.ListenAndServe(port, router))
}