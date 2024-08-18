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
}

type Quiz struct {
	Questions []Question `json:"questions"`
}

var quiz = Quiz{
	Questions: []Question{
		{ID: 1, Text: "What is the capital of France?", Options: []string{"London", "Berlin", "Paris", "Madrid"}, Answer: 2},
		{ID: 2, Text: "Which planet is known as the Red Planet?", Options: []string{"Venus", "Mars", "Jupiter", "Saturn"}, Answer: 1},
		{ID: 3, Text: "What is the largest mammal?", Options: []string{"Elephant", "Blue Whale", "Giraffe", "Hippopotamus"}, Answer: 1},
		{ID: 4, Text: "Who painted the Mona Lisa?", Options: []string{"Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"}, Answer: 2},
		{ID: 5, Text: "What is the chemical symbol for gold?", Options: []string{"Go", "Gd", "Au", "Ag"}, Answer: 2},
		{ID: 6, Text: "Which country is home to the kangaroo?", Options: []string{"New Zealand", "South Africa", "Australia", "Brazil"}, Answer: 2},
		{ID: 7, Text: "What is the largest planet in our solar system?", Options: []string{"Earth", "Mars", "Jupiter", "Saturn"}, Answer: 2},
	},
}

func getQuiz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(quiz)
}

func main() {
	router := mux.NewRouter()

	router.HandleFunc("/api/quiz", getQuiz).Methods("GET")

	log.Println("Server is running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", router))
}