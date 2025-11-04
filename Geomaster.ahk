/*
Script: Geomaster
Συγγραφέας: Tasos
Έτος: 2025
MIT License
Copyright (c) 2025 Tasos
*/
#Requires AutoHotkey v2.0
#SingleInstance Force

; ═══════════════════════════════════════════════════════════════════════════════
; CONFIGURATION CONSTANTS
; ═══════════════════════════════════════════════════════════════════════════════

class Config {
    static NEXT_QUESTION_DELAY := 1500
    static MAX_PLAYER_NAME_LENGTH := 20
    static MAX_COUNTRY_NAME_DISPLAY := 25
    static CHALLENGE_TOTAL_QUESTIONS := 100
    static QUESTIONS_PER_ROUND := 25
    static VERSION := "1.0"
}

class Difficulty {
    static EASY := {name: "Easy", timer: 15, options: 4, penalty: false, hints: 5, color: "10B981"}
    static NORMAL := {name: "Normal", timer: 10, options: 4, penalty: false, hints: 3, color: "3B82F6"}
    static HARD := {name: "Hard", timer: 7, options: 4, penalty: true, hints: 1, color: "F59E0B"}
    static EXPERT := {name: "Expert", timer: 5, options: 4, penalty: true, hints: 0, color: "EF4444"}
    
    static Current := this.NORMAL
}

class Colors {
    ; Light mode
    static PRIMARY_BLUE := "3B82F6"
    static AMBER := "F59E0B"
    static GREEN := "10B981"
    static VIOLET := "8B5CF6"
    static RED := "EF4444"
    static SUCCESS := "00AA00"
    static ERROR := "FF0000"
    static TIMER_NORMAL := "DC2626"
    static TIMER_WARNING := "FF6600"
    static TIMER_CRITICAL := "FF0000"
    static HEADER := "1E293B"
    static TEXT := "475569"
    static BACKGROUND := "F0F4F8"
    static PROGRESS := "10B981"
    static PROGRESS_BG := "E2E8F0"
    
    ; Dark mode
    static DARK_BACKGROUND := "1E293B"
    static DARK_TEXT := "E2E8F0"
    static DARK_HEADER := "F8FAFC"
    static DARK_CARD := "334155"
}

class Resources {
    static FLAGS_DIR := "flags\"
    static SHAPES_DIR := "shape\"
    static HIGHSCORES_FILE := "Highscores.ini"
    static STATS_FILE := "Statistics.ini"
    static IMAGE_EXT := ".PNG"
    
    static GetFlagPath(country) => this.FLAGS_DIR . country . this.IMAGE_EXT
    static GetShapePath(country) => this.SHAPES_DIR . country . this.IMAGE_EXT
}

class Sounds {
    static ENABLED := true
    
    static Correct() {
        If this.ENABLED
            SoundBeep(1000, 100)
    }
    
    static Wrong() {
        If this.ENABLED
            SoundBeep(400, 200)
    }
    
    static Tick() {
        If this.ENABLED
            SoundBeep(800, 50)
    }
    
    static Complete() {
        If this.ENABLED {
            SoundBeep(800, 100)
            Sleep 50
            SoundBeep(1000, 100)
            Sleep 50
            SoundBeep(1200, 150)
        }
    }
    
    static Streak() {
        If this.ENABLED
            SoundBeep(1500, 80)
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; STATISTICS CLASS
; ═══════════════════════════════════════════════════════════════════════════════

class Stats {
    static TotalGames := 0
    static TotalCorrect := 0
    static TotalWrong := 0
    static BestStreak := 0
    static FastestAnswer := 999
    static QuizTypeCount := Map()
    static TotalPlayTime := 0
    static StartTime := 0
    
    static Load() {
        If !FileExist(Resources.STATS_FILE)
            Return
        
        Try {
            this.TotalGames := Integer(IniRead(Resources.STATS_FILE, "General", "TotalGames", 0))
            this.TotalCorrect := Integer(IniRead(Resources.STATS_FILE, "General", "TotalCorrect", 0))
            this.TotalWrong := Integer(IniRead(Resources.STATS_FILE, "General", "TotalWrong", 0))
            this.BestStreak := Integer(IniRead(Resources.STATS_FILE, "General", "BestStreak", 0))
            this.FastestAnswer := Float(IniRead(Resources.STATS_FILE, "General", "FastestAnswer", 999))
            this.TotalPlayTime := Integer(IniRead(Resources.STATS_FILE, "General", "TotalPlayTime", 0))
            
            ; Initialize QuizTypeCount Map with default values
            this.QuizTypeCount := Map()
            this.QuizTypeCount["Flags"] := Integer(IniRead(Resources.STATS_FILE, "QuizTypes", "Flags", 0))
            this.QuizTypeCount["Countries Shapes"] := Integer(IniRead(Resources.STATS_FILE, "QuizTypes", "Shapes", 0))
            this.QuizTypeCount["Country By Capital"] := Integer(IniRead(Resources.STATS_FILE, "QuizTypes", "CountryCapital", 0))
            this.QuizTypeCount["Capital By Country"] := Integer(IniRead(Resources.STATS_FILE, "QuizTypes", "CapitalCountry", 0))
            this.QuizTypeCount["Challenge"] := Integer(IniRead(Resources.STATS_FILE, "QuizTypes", "Challenge", 0))
        }
    }
    
    static Save() {
        ; Ensure QuizTypeCount Map exists with all keys
        If !this.QuizTypeCount.Has("Flags")
            this.QuizTypeCount["Flags"] := 0
        If !this.QuizTypeCount.Has("Countries Shapes")
            this.QuizTypeCount["Countries Shapes"] := 0
        If !this.QuizTypeCount.Has("Country By Capital")
            this.QuizTypeCount["Country By Capital"] := 0
        If !this.QuizTypeCount.Has("Capital By Country")
            this.QuizTypeCount["Capital By Country"] := 0
        If !this.QuizTypeCount.Has("Challenge")
            this.QuizTypeCount["Challenge"] := 0
        
        IniWrite(this.TotalGames, Resources.STATS_FILE, "General", "TotalGames")
        IniWrite(this.TotalCorrect, Resources.STATS_FILE, "General", "TotalCorrect")
        IniWrite(this.TotalWrong, Resources.STATS_FILE, "General", "TotalWrong")
        IniWrite(this.BestStreak, Resources.STATS_FILE, "General", "BestStreak")
        IniWrite(this.FastestAnswer, Resources.STATS_FILE, "General", "FastestAnswer")
        IniWrite(this.TotalPlayTime, Resources.STATS_FILE, "General", "TotalPlayTime")
        
        IniWrite(this.QuizTypeCount["Flags"], Resources.STATS_FILE, "QuizTypes", "Flags")
        IniWrite(this.QuizTypeCount["Countries Shapes"], Resources.STATS_FILE, "QuizTypes", "Shapes")
        IniWrite(this.QuizTypeCount["Country By Capital"], Resources.STATS_FILE, "QuizTypes", "CountryCapital")
        IniWrite(this.QuizTypeCount["Capital By Country"], Resources.STATS_FILE, "QuizTypes", "CapitalCountry")
        IniWrite(this.QuizTypeCount["Challenge"], Resources.STATS_FILE, "QuizTypes", "Challenge")
    }
    
    static RecordGame(quizType) {
        this.TotalGames++
        If !this.QuizTypeCount.Has(quizType)
            this.QuizTypeCount[quizType] := 0
        this.QuizTypeCount[quizType]++
        
        ; Calculate play time
        If (this.StartTime > 0) {
            playTime := (A_TickCount - this.StartTime) // 1000
            this.TotalPlayTime += playTime
        }
        
        this.Save()
    }
    
    static RecordAnswer(correct, timeToAnswer) {
        If correct {
            this.TotalCorrect++
            If (timeToAnswer < this.FastestAnswer)
                this.FastestAnswer := timeToAnswer
        } Else {
            this.TotalWrong++
        }
    }
    
    static RecordStreak(streak) {
        If (streak > this.BestStreak)
            this.BestStreak := streak
    }
    
    static GetAccuracy() {
        total := this.TotalCorrect + this.TotalWrong
        Return (total > 0) ? Round((this.TotalCorrect / total) * 100, 1) : 0
    }
    
    static GetAverageScore() {
        Return (this.TotalGames > 0) ? Round(this.TotalCorrect / this.TotalGames, 1) : 0
    }
    
    static GetFavoriteQuizType() {
        maxCount := 0
        favorite := "None"
        For type, count in this.QuizTypeCount {
            If (count > maxCount) {
                maxCount := count
                favorite := type
            }
        }
        Return favorite
    }
    
    static Display() {
        message := "📊 YOUR STATISTICS`n"
        message .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n`n"
        message .= "🎮 Games Played: " . this.TotalGames . "`n"
        message .= "✅ Correct Answers: " . this.TotalCorrect . "`n"
        message .= "❌ Wrong Answers: " . this.TotalWrong . "`n"
        message .= "📈 Accuracy: " . this.GetAccuracy() . "%`n"
        message .= "⭐ Average Score: " . this.GetAverageScore() . "`n`n"
        message .= "🔥 Best Streak: " . this.BestStreak . "`n"
        message .= "⚡ Fastest Answer: " . (this.FastestAnswer < 999 ? Round(this.FastestAnswer, 1) . "s" : "N/A") . "`n"
        message .= "⏱️ Total Play Time: " . FormatPlayTime(this.TotalPlayTime) . "`n`n"
        message .= "❤️ Favorite Type: " . this.GetFavoriteQuizType()
        
        MsgBox(message, "Statistics - Geomaster v" . Config.VERSION, 64)
    }
    
    static Reset() {
        result := MsgBox("Are you sure you want to reset ALL statistics?`n`nThis cannot be undone!", "Reset Statistics", 4 + 48)
        If (result = "Yes") {
            this.TotalGames := 0
            this.TotalCorrect := 0
            this.TotalWrong := 0
            this.BestStreak := 0
            this.FastestAnswer := 999
            this.TotalPlayTime := 0
            this.QuizTypeCount := Map()
            this.QuizTypeCount["Flags"] := 0
            this.QuizTypeCount["Countries Shapes"] := 0
            this.QuizTypeCount["Country By Capital"] := 0
            this.QuizTypeCount["Capital By Country"] := 0
            this.QuizTypeCount["Challenge"] := 0
            this.Save()
            MsgBox("Statistics have been reset!", "Reset Complete", 64)
        }
    }
}

FormatPlayTime(seconds) {
    hours := seconds // 3600
    minutes := (seconds // 60) - (hours * 60)
    If (hours > 0)
        Return hours . "h " . minutes . "m"
    Return minutes . "m"
}

; ═══════════════════════════════════════════════════════════════════════════════
; GLOBAL VARIABLES
; ═══════════════════════════════════════════════════════════════════════════════

Global Countries, CountriesGreek, CurrentCountry, CurrentCapital, Score, TotalQuestions
Global MaxQuestions := 10, QuizType := "Flags", AnswerSelected := false, GameStarted := false
Global TimeLeft := 0, TimerActive := false, ShuffledOptions := [], IsProcessingQuestion := false, ChallengeRound := 0
Global HighScores := Map(), CurrentPlayer := "Player"
Global MissingFlags := [], MissingShapes := []
Global HeaderTitle  ; <-- ΠΡΟΣΘΗΚΗ ΑΥΤΗΣ ΤΗΣ ΓΡΑΜΜΗΣ
Global IsProcessingQuestion := false


; NEW: Feature globals
Global CurrentStreak := 0, BestStreakThisGame := 0
Global HintsLeft := 3
Global IsDarkMode := false
Global QuestionStartTime := 0

ChallengeTypes := ["Flags", "Countries Shapes", "Country By Capital", "Capital By Country"]

; ═══════════════════════════════════════════════════════════════════════════════
; INITIALIZATION
; ═══════════════════════════════════════════════════════════════════════════════

LoadHighScores()
Stats.Load()
OnExit(CleanupOnExit)

; ═══════════════════════════════════════════════════════════════════════════════
; GUI CREATION
; ═══════════════════════════════════════════════════════════════════════════════

TraySetIcon("Shell32.dll", 44)
MyGui := Gui()
MyGui.BackColor := Colors.BACKGROUND
MyGui.Opt("-Resize +MaximizeBox +MinimizeBox")
MyGui.MarginX := 15
MyGui.MarginY := 15

; Header with version
MyGui.SetFont("s22 Bold c" . Colors.HEADER, "Segoe UI")
HeaderTitle := MyGui.Add("Text", "x50 y15 w900 h45 Center BackgroundTrans", "🌍 GEOMASTER 🌎")

; Top menu buttons
MyGui.SetFont("s10 Bold cFFFFFF", "Segoe UI")
StatsBtn := MyGui.Add("Button", "x10 y10 w90 h35 Background" . Colors.VIOLET, "📊 Stats")
StatsBtn.OnEvent("Click", (*) => Stats.Display())

DarkModeBtn := MyGui.Add("Button", "x110 y10 w90 h35 Background" . Colors.HEADER, "🌙 Dark")
DarkModeBtn.OnEvent("Click", ToggleDarkMode)

SoundBtn := MyGui.Add("Button", "x210 y10 w90 h35 Background" . Colors.GREEN, "🔊 Sound")
SoundBtn.OnEvent("Click", ToggleSound)

; Main selection area
MyGui.SetFont("s15 c" . Colors.TEXT, "Segoe UI")  ; από s16 → s15
SelectQuizTypeText := MyGui.Add("Text", "x0 y70 w1000 h35 Center BackgroundTrans", "SELECT QUIZ TYPE")  ; από y80 h40

; Quiz type selection
MyGui.SetFont("s11 cFFFFFF", "Segoe UI")  ; από s12 → s11
FlagsQuiz := MyGui.Add("Radio", "x50 y115 w280 h42 vFlagsQuiz Background" . Colors.PRIMARY_BLUE . " Checked", "🚩 FLAGS")
FlagsQuiz.OnEvent("Click", OnQuizTypeChange)
ShapesQuiz := MyGui.Add("Radio", "x50 y165 w280 h42 vShapesQuiz Background" . Colors.AMBER, "🗺️ SHAPES")
ShapesQuiz.OnEvent("Click", OnQuizTypeChange)
CountryCapitalQuiz := MyGui.Add("Radio", "x50 y215 w280 h42 vCountryCapitalQuiz Background" . Colors.GREEN, "🏛️ COUNTRY → CAPITAL")
CountryCapitalQuiz.OnEvent("Click", OnQuizTypeChange)
CapitalCountryQuiz := MyGui.Add("Radio", "x50 y265 w280 h42 vCapitalCountryQuiz Background" . Colors.VIOLET, "🌆 CAPITAL → COUNTRY")
CapitalCountryQuiz.OnEvent("Click", OnQuizTypeChange)
ChallengeQuiz := MyGui.Add("Radio", "x50 y315 w280 h42 vChallengeQuiz Background" . Colors.RED, "🏆 CHALLENGE MODE")
ChallengeQuiz.OnEvent("Click", OnQuizTypeChange)

; Difficulty selection
MyGui.SetFont("s11 c" . Colors.TEXT, "Segoe UI")  ; από s12 → s11
DifficultyText := MyGui.Add("Text", "x350 y115 w150 h30 BackgroundTrans", "DIFFICULTY:")
MyGui.SetFont("s10 cFFFFFF", "Segoe UI")
EasyDiff := MyGui.Add("Radio", "x490 y115 w100 h28 vEasyDiff Background" . Difficulty.EASY.color, "😊 Easy")
EasyDiff.OnEvent("Click", (*) => SetDifficulty(Difficulty.EASY))
NormalDiff := MyGui.Add("Radio", "x590 y115 w100 h28 vNormalDiff Checked Background" . Difficulty.NORMAL.color, "😐 Normal")
NormalDiff.OnEvent("Click", (*) => SetDifficulty(Difficulty.NORMAL))
HardDiff := MyGui.Add("Radio", "x490 y148 w100 h28 vHardDiff Background" . Difficulty.HARD.color, "😰 Hard")
HardDiff.OnEvent("Click", (*) => SetDifficulty(Difficulty.HARD))
ExpertDiff := MyGui.Add("Radio", "x590 y148 w100 h28 vExpertDiff Background" . Difficulty.EXPERT.color, "💀 Expert")
ExpertDiff.OnEvent("Click", (*) => SetDifficulty(Difficulty.EXPERT))

; Player name input
MyGui.SetFont("s11 c" . Colors.TEXT, "Segoe UI")
PlayerNameText := MyGui.Add("Text", "x350 y185 w150 h30 BackgroundTrans", "PLAYER NAME:")
PlayerName := MyGui.Add("Edit", "x490 y185 w200 h32 vPlayerName c" . Colors.HEADER . " BackgroundFFFFFF", "Player")
PlayerName.OnEvent("Change", OnPlayerNameChange)

; Questions selection
QuestionsText := MyGui.Add("Text", "x350 y230 w150 h30 BackgroundTrans", "QUESTIONS:")
Questions10 := MyGui.Add("Radio", "x490 y230 w60 h32 vQuestions10 Checked", "10")
Questions10.OnEvent("Click", OnQuestionsChange)
Questions25 := MyGui.Add("Radio", "x540 y230 w60 h32 vQuestions25", "25")
Questions25.OnEvent("Click", OnQuestionsChange)
Questions50 := MyGui.Add("Radio", "x590 y230 w60 h32 vQuestions50", "50")
Questions50.OnEvent("Click", OnQuestionsChange)
QuestionsAll := MyGui.Add("Radio", "x640 y230 w60 h32 vQuestionsAll", "All")
QuestionsAll.OnEvent("Click", OnQuestionsChange)

; High scores display
MyGui.SetFont("s13 Bold c" . Colors.TIMER_NORMAL, "Segoe UI")  ; από s14 → s13
HighScoresTitle := MyGui.Add("Text", "x750 y120 w250 h30 BackgroundTrans", "🏆 HIGH SCORES")
MyGui.SetFont("s9 c" . Colors.TEXT, "Segoe UI")  ; από s10 → s9
HighScoresText := MyGui.Add("Text", "x750 y155 w250 h210 BackgroundTrans", FormatHighScores())

; Start button
MyGui.SetFont("s16 Bold cFFFFFF", "Segoe UI")  ; από s18 → s16
StartButton := MyGui.Add("Button", "x400 y285 w200 h50 Background1D4ED8", "🎮 START QUIZ")  ; από y320 h55
StartButton.OnEvent("Click", StartQuiz)

; Game area (initially hidden)
MyGui.SetFont("s18 Bold c" . Colors.HEADER, "Segoe UI")  ; από s20 → s18
QuestionText := MyGui.Add("Text", "x0 y75 w1000 h55 Center BackgroundTrans Hidden", "Find the country:")

; Streak display
MyGui.SetFont("s13 Bold c" . Colors.AMBER, "Segoe UI")  ; από s14 → s13
StreakText := MyGui.Add("Text", "x730 y110 w250 h30 Right BackgroundTrans Hidden", "🔥 Streak: 0")

; Timer
MyGui.SetFont("s15 Bold c" . Colors.TIMER_NORMAL, "Segoe UI")  ; από s16 → s15
TimerText := MyGui.Add("Text", "x0 y135 w1000 h35 Center BackgroundTrans Hidden", "⏱️ Time: 10s")

; Hint button
MyGui.SetFont("s11 Bold cFFFFFF", "Segoe UI")  ; από s12 → s11
HintBtn := MyGui.Add("Button", "x850 y185 w140 h45 Background" . Colors.VIOLET . " Hidden", "💡 HINT (3)")
HintBtn.OnEvent("Click", UseHint)

FlagPic := MyGui.Add("Picture", "x420 y195 w180 h120 Center BackgroundTrans Hidden")
ShapePic := MyGui.Add("Picture", "x420 y195 w180 h150 Center BackgroundTrans Hidden")

; Option buttons
MyGui.SetFont("s13 cFFFFFF", "Segoe UI")  ; από s14 → s13
Option1Btn := MyGui.Add("Button", "x200 y420 w350 h60 vOption1 Background" . Colors.PRIMARY_BLUE . " Hidden", "Option 1")
Option1Btn.OnEvent("Click", Option1)
Option2Btn := MyGui.Add("Button", "x200 y495 w350 h60 vOption2 Background" . Colors.AMBER . " Hidden", "Option 2")
Option2Btn.OnEvent("Click", Option2)
Option3Btn := MyGui.Add("Button", "x570 y420 w350 h60 vOption3 Background" . Colors.GREEN . " Hidden", "Option 3")
Option3Btn.OnEvent("Click", Option3)
Option4Btn := MyGui.Add("Button", "x570 y495 w350 h60 vOption4 Background" . Colors.VIOLET . " Hidden", "Option 4")
Option4Btn.OnEvent("Click", Option4)

; Result and score display
MyGui.SetFont("s16 Bold c" . Colors.HEADER, "Segoe UI")  ; από s18 → s16
ResultText := MyGui.Add("Text", "x0 y590 w1000 h50 Center BackgroundTrans Hidden")
MyGui.SetFont("s14 c" . Colors.TEXT, "Segoe UI")  ; από s16 → s14
ScoreInfoText := MyGui.Add("Text", "x0 y625 w1000 h35 Center BackgroundTrans Hidden", "Score: 0/0")

ProgressBar := MyGui.Add("Progress", "x250 y635 w500 h20 c" . Colors.PROGRESS . " Background" . Colors.PROGRESS_BG . " Hidden", 0)  ; από y665 h22 → y635 h20

; Action buttons
MyGui.SetFont("s13 Bold cFFFFFF", "Segoe UI")  ; από s14 → s13
PlayAgainBtn := MyGui.Add("Button", "x810 y663 w180 h45 Background" . Colors.AMBER . " Hidden", "🔄 Play Again")  ; από y693 → y663
PlayAgainBtn.OnEvent("Click", PlayAgain)
MainMenuBtn := MyGui.Add("Button", "x10 y663 w180 h45 Background" . Colors.PRIMARY_BLUE . " Hidden", "🏠 Main Menu")  ; από y693 → y663
MainMenuBtn.OnEvent("Click", MainMenu)

; Footer
MyGui.SetFont("s14 c" . Colors.TEXT, "Segoe UI")  ; από s16 → s14
ScoreInfoText := MyGui.Add("Text", "x0 y695 w1000 h35 Center BackgroundTrans Hidden", "Score: 0/0")

MyGui.Show("w1000 h760")
MyGui.Title := "Geomaster"

; Add close event handlers
MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.OnEvent("Escape", (*) => ExitApp())

; ═══════════════════════════════════════════════════════════════════════════════
; COUNTRY DATA
; ═══════════════════════════════════════════════════════════════════════════════

Countries := ["Afghanistan", "Aland Islands", "Albania", "Algeria", "American Samoa", "Andorra", "Angola", "Anguilla", "Antarctica", "Antigua and Barbuda", "Argentina", "Armenia", "Aruba", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bermuda", "Bhutan", "Bolivia, Plurinational State of", "Bonaire, Sint Eustatius and Saba", "Bosnia and Herzegovina", "Botswana", "Bouvet Island", "Brazil", "British Indian Ocean Territory", "Brunei Darussalam", "Bulgaria", "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia", "Cameroon", "Canada", "Cayman Islands", "Central African Republic", "Chad", "Chile", "China", "Christmas Island", "Cocos (Keeling) Islands", "Colombia", "Comoros", "Congo, The Democratic Republic of the", "Congo", "Cook Islands", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba", "Curacao", "Cyprus", "Czechia", "Denmark", "Djibouti", "Dominica", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Falkland Islands (Malvinas)", "Faroe Islands", "Fiji", "Finland", "France", "French Guiana", "French Polynesia", "French Southern Territories", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Gibraltar", "Greece", "Greenland", "Grenada", "Guadeloupe", "Guam", "Guatemala", "Guernsey", "Guinea-Bissau", "Guinea", "Guyana", "Haiti", "Heard Island and McDonald Islands", "Holy See (Vatican City State)", "Honduras", "Hong Kong", "Hungary", "Iceland", "India", "Indonesia", "Iran, Islamic Republic of", "Iraq", "Ireland", "Isle of Man", "Israel", "Italy", "Jamaica", "Japan", "Jersey", "Jordan", "Kazakhstan", "Kenya", "Kiribati", "Korea, Democratic People's Republic of", "Korea, Republic of", "Kuwait", "Kyrgyzstan", "Lao People's Democratic Republic", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg", "Macao", "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Martinique", "Mauritania", "Mauritius", "Mayotte", "Mexico", "Micronesia, Federated States of", "Moldova, Republic of", "Monaco", "Mongolia", "Montenegro", "Montserrat", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", "Netherlands", "New Caledonia", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Niue", "Norfolk Island", "North Macedonia", "Northern Mariana Islands", "Norway", "Oman", "Pakistan", "Palau", "Palestine, State of", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Pitcairn", "Poland", "Portugal", "Puerto Rico", "Qatar", "Republic of Kosovo", "Reunion", "Romania", "Russian Federation", "Rwanda", "Saint Barthelemy", "Saint Helena, Ascension and Tristan da Cunha", "Saint Kitts and Nevis", "Saint Lucia", "Saint Martin (French part)", "Saint Pierre and Miquelon", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Sint Maarten (Dutch part)", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Georgia and the Sandwich Islands", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Svalbard and Jan Mayen", "Sweden", "Switzerland", "Syrian Arab Republic", "Taiwan, Province of China", "Tajikistan", "Tanzania, United Republic of", "Thailand", "Timor-Leste", "Togo", "Tokelau", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Turks and Caicos Islands", "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan", "Vanuatu", "Venezuela, Bolivarian Republic of", "Viet Nam", "Virgin Islands, British", "Virgin Islands, U.S.", "Wallis and Futuna", "Western Sahara", "Yemen", "Zambia", "Zimbabwe"]

CountriesGreek := Map("Afghanistan", "Kabul", "Albania", "Tirana", "Algeria", "Algiers", "Andorra", "Andorra la Vella", "Angola", "Luanda", "Antigua and Barbuda", "Saint John's", "Argentina", "Buenos Aires", "Armenia", "Yerevan", "Australia", "Canberra", "Austria", "Vienna", "Azerbaijan", "Baku", "Bahamas", "Nassau", "Bahrain", "Manama", "Bangladesh", "Dhaka", "Barbados", "Bridgetown", "Belarus", "Minsk", "Belgium", "Brussels", "Belize", "Belmopan", "Benin", "Porto-Novo", "Bhutan", "Thimphu", "Bolivia", "Sucre", "Bosnia and Herzegovina", "Sarajevo", "Botswana", "Gaborone", "Brazil", "Brasilia", "Brunei", "Bandar Seri Begawan", "Bulgaria", "Sofia", "Burkina Faso", "Ouagadougou", "Burundi", "Gitega", "Cambodia", "Phnom Penh", "Cameroon", "Yaounde", "Canada", "Ottawa", "Cape Verde", "Praia", "Central African Republic", "Bangui", "Chad", "N'Djamena", "Chile", "Santiago", "China", "Beijing", "Colombia", "Bogota", "Comoros", "Moroni", "Congo (Republic)", "Brazzaville", "Congo (Democratic Republic)", "Kinshasa", "Costa Rica", "San Jose", "Croatia", "Zagreb", "Cuba", "Havana", "Cyprus", "Nicosia", "Czechia", "Prague", "Denmark", "Copenhagen", "Djibouti", "Djibouti", "Dominica", "Roseau", "Dominican Republic", "Santo Domingo", "East Timor", "Dili", "Ecuador", "Quito", "Egypt", "Cairo", "El Salvador", "San Salvador", "Equatorial Guinea", "Malabo", "Eritrea", "Asmara", "Estonia", "Tallinn", "Eswatini (Swaziland)", "Mbabane", "Ethiopia", "Addis Ababa", "Fiji", "Suva", "Finland", "Helsinki", "France", "Paris", "Gabon", "Libreville", "Gambia", "Banjul", "Georgia", "Tbilisi", "Germany", "Berlin", "Ghana", "Accra", "Greece", "Athens", "Grenada", "St. George's", "Guatemala", "Guatemala City", "Guinea", "Conakry", "Guinea-Bissau", "Bissau", "Guyana", "Georgetown", "Haiti", "Port-au-Prince", "Honduras", "Tegucigalpa", "Hungary", "Budapest", "Iceland", "Reykjavik", "India", "New Delhi", "Indonesia", "Jakarta", "Iran", "Tehran", "Iraq", "Baghdad", "Ireland", "Dublin", "Israel", "Jerusalem", "Italy", "Rome", "Ivory Coast", "Yamoussoukro", "Jamaica", "Kingston", "Japan", "Tokyo", "Jordan", "Amman", "Kazakhstan", "Astana", "Kenya", "Nairobi", "Kiribati", "South Tarawa", "North Korea", "Pyongyang", "South Korea", "Seoul", "Kosovo", "Pristina", "Kuwait", "Kuwait City", "Kyrgyzstan", "Bishkek", "Laos", "Vientiane", "Latvia", "Riga", "Lebanon", "Beirut", "Lesotho", "Maseru", "Liberia", "Monrovia", "Libya", "Tripoli", "Liechtenstein", "Vaduz", "Lithuania", "Vilnius", "Luxembourg", "Luxembourg", "Madagascar", "Antananarivo", "Malawi", "Lilongwe", "Malaysia", "Kuala Lumpur", "Maldives", "Male", "Mali", "Bamako", "Malta", "Valletta", "Marshall Islands", "Majuro", "Mauritania", "Nouakchott", "Mauritius", "Port Louis", "Mexico", "Mexico City", "Micronesia", "Palikir", "Moldova", "Chisinău", "Monaco", "Monaco", "Mongolia", "Ulaanbaatar", "Montenegro", "Podgorica", "Morocco", "Rabat", "Mozambique", "Maputo", "Myanmar", "Naypyidaw", "Namibia", "Windhoek", "Nepal", "Kathmandu", "Netherlands", "Amsterdam", "New Zealand", "Wellington", "Nicaragua", "Managua", "Niger", "Niamey", "Nigeria", "Abuja", "North Macedonia", "Skopje", "Norway", "Oslo", "Oman", "Muscat", "Pakistan", "Islamabad", "Palestine", "East Jerusalem", "Palau", "Ngerulmud", "Panama", "Panama City", "Papua New Guinea", "Port Moresby", "Paraguay", "Asuncion", "Peru", "Lima", "Philippines", "Manila", "Poland", "Warsaw", "Portugal", "Lisbon", "Puerto Rico", "San Juan", "Qatar", "Doha", "Romania", "Bucharest", "Russia", "Moscow", "Rwanda", "Kigali", "Saint Kitts and Nevis", "Basseterre", "Saint Lucia", "Castries", "Saint Vincent and the Grenadines", "Kingstown", "Samoa", "Apia", "San Marino", "San Marino", "Sao Tome and Principe", "Sao Tome", "Saudi Arabia", "Riyadh", "Senegal", "Dakar", "Serbia", "Belgrade", "Seychelles", "Victoria", "Sierra Leone", "Freetown", "Singapore", "Singapore", "Slovakia", "Bratislava", "Slovenia", "Ljubljana", "Solomon Islands", "Honiara", "Somalia", "Mogadishu", "South Africa", "Pretoria", "South Sudan", "Juba", "Spain", "Madrid", "Sri Lanka", "Sri Jayawardenepura Kotte", "Sudan", "Khartoum", "Suriname", "Paramaribo", "Sweden", "Stockholm", "Switzerland", "Bern", "Syria", "Damascus", "Taiwan", "Taipei", "Tajikistan", "Dushanbe", "Tanzania", "Dodoma", "Thailand", "Bangkok", "Togo", "Lome", "Tonga", "Nuku'alofa", "Trinidad and Tobago", "Port of Spain", "Tunisia", "Tunis", "Turkey", "Ankara", "Turkmenistan", "Ashgabat", "Tuvalu", "Funafuti", "Uganda", "Kampala", "Ukraine", "Kyiv", "United Arab Emirates", "Abu Dhabi", "United Kingdom", "London", "United States", "Washington, D.C.", "Uruguay", "Montevideo", "Uzbekistan", "Tashkent", "Vanuatu", "Port Vila", "Vatican City", "Vatican City", "Venezuela", "Caracas", "Vietnam", "Hanoi", "Yemen", "Sana'a", "Zambia", "Lusaka", "Zimbabwe", "Harare")

ValidateResources()

; ═══════════════════════════════════════════════════════════════════════════════
; NEW FEATURES - EVENT HANDLERS
; ═══════════════════════════════════════════════════════════════════════════════

SetDifficulty(diff) {
    Difficulty.Current := diff
    HintsLeft := diff.hints
    HintBtn.Text := "💡 HINT (" . HintsLeft . ")"
}

ToggleDarkMode(*) {
    Global IsDarkMode, HeaderTitle
    IsDarkMode := !IsDarkMode
    
    If (IsDarkMode) {
        ; Dark mode colors
        MyGui.BackColor := Colors.DARK_BACKGROUND
        DarkModeBtn.Text := "☀️ Light"

        ; Header title - ΤΩΡΑ ΘΑ ΔΟΥΛΕΥΕΙ!
        HeaderTitle.Opt("c" . Colors.DARK_HEADER)
        
        ; Menu text
        SelectQuizTypeText.Opt("c" . Colors.DARK_TEXT)
        DifficultyText.Opt("c" . Colors.DARK_TEXT)
        PlayerNameText.Opt("c" . Colors.DARK_TEXT)
        QuestionsText.Opt("c" . Colors.DARK_TEXT)
        HighScoresText.Opt("c" . Colors.DARK_TEXT)
        HighScoresTitle.Opt("c" . Colors.DARK_TEXT)
        
        ; Game text (if visible)
        QuestionText.Opt("c" . Colors.DARK_HEADER)
        ResultText.Opt("c" . Colors.DARK_TEXT)
        ScoreInfoText.Opt("c" . Colors.DARK_TEXT)
        StreakText.Opt("c" . Colors.DARK_TEXT)
        TimerText.Opt("c" . Colors.DARK_TEXT)
        
    } Else {
        ; Light mode colors
        MyGui.BackColor := Colors.BACKGROUND
        DarkModeBtn.Text := "🌙 Dark"

        ; Header title
        HeaderTitle.Opt("c" . Colors.HEADER)
        
        ; Menu text
        SelectQuizTypeText.Opt("c" . Colors.TEXT)
        DifficultyText.Opt("c" . Colors.TEXT)
        PlayerNameText.Opt("c" . Colors.TEXT)
        QuestionsText.Opt("c" . Colors.TEXT)
        HighScoresText.Opt("c" . Colors.TEXT)
        HighScoresTitle.Opt("c" . Colors.TIMER_NORMAL)
        
        ; Game text (if visible)
        QuestionText.Opt("c" . Colors.HEADER)
        ResultText.Opt("c" . Colors.HEADER)
        ScoreInfoText.Opt("c" . Colors.TEXT)
        StreakText.Opt("c" . Colors.TEXT)
        TimerText.Opt("c" . Colors.TIMER_NORMAL)
        
    }
}

ToggleSound(*) {
    Sounds.ENABLED := !Sounds.ENABLED
    SoundBtn.Text := Sounds.ENABLED ? "🔊 Sound" : "🔇 Muted"
    If Sounds.ENABLED
        Sounds.Correct()
}

UseHint(*) {
    Global HintsLeft, ShuffledOptions, CurrentCountry, CurrentCapital, QuizType, ChallengeRound, ChallengeTypes
    
    If (HintsLeft <= 0) {
        ShowWarning("No Hints Left", "You have no hints remaining for this game!")
        Return
    }
    
    ; Validate ShuffledOptions exists and has content
    If (!IsObject(ShuffledOptions) || ShuffledOptions.Length < 4) {
        ShowWarning("Hint Error", "Cannot use hint at this time!")
        Return
    }
    
    ; Determine current quiz type
    If (QuizType = "Challenge") {
        CurrentQuizType := ChallengeTypes[ChallengeRound]
    } Else {
        CurrentQuizType := QuizType
    }
    
    ; Find wrong options
    wrongOptions := []
    Loop 4 {
        isWrong := false
        testAnswer := ShuffledOptions[A_Index]
        
        If (CurrentQuizType = "Flags" || CurrentQuizType = "Countries Shapes") {
            isWrong := (testAnswer != CurrentCountry)
        } Else If (CurrentQuizType = "Country By Capital") {
            isWrong := (testAnswer != CurrentCapital)
        } Else If (CurrentQuizType = "Capital By Country") {
            normalizedTest := NormalizeCountryName(testAnswer)
            isWrong := (normalizedTest != CurrentCountry && testAnswer != CurrentCountry)
        }
        
        If isWrong
            wrongOptions.Push(A_Index)
    }
    
    ; Check if we have enough wrong options
    If (wrongOptions.Length < 2) {
        ShowWarning("Hint Error", "Not enough options to remove!")
        Return
    }
    
    ; Disable 2 random wrong options
    Loop 2 {
        If (wrongOptions.Length > 0) {
            idx := wrongOptions.RemoveAt(Random(1, wrongOptions.Length))
            MyGui["Option" . idx].Enabled := false
            MyGui["Option" . idx].Opt("BackgroundCCCCCC")
        }
    }
    
    HintsLeft--
    HintBtn.Text := "💡 HINT (" . HintsLeft . ")"
    Sounds.Tick()
}

UpdateStreakDisplay() {
    Global CurrentStreak, BestStreakThisGame
    
    If (CurrentStreak >= 5) {
        StreakText.Opt("c" . Colors.RED)
        StreakText.Value := "🔥 STREAK: " . CurrentStreak . " 🔥"
    } Else If (CurrentStreak >= 3) {
        StreakText.Opt("c" . Colors.AMBER)
        StreakText.Value := "🔥 Streak: " . CurrentStreak
    } Else {
        StreakText.Opt("c" . Colors.TEXT)
        StreakText.Value := "🔥 Streak: " . CurrentStreak
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; HELPER FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════

ShowError(title, message) {
    MsgBox("❌ ERROR: " . title . "`n`n" . message, "Geomaster Error", 16)
}

ShowWarning(title, message) {
    MsgBox("⚠️ WARNING: " . title . "`n`n" . message, "Geomaster Warning", 48)
}

ShowSuccess(title, message) {
    MsgBox("✅ " . title . "`n`n" . message, "Geomaster", 64)
}

PositionQuizButtons() {
    positions := [
        [150, 440, 350, 60],    ; από y450 h65
        [150, 515, 350, 60],    ; από y530 h65
        [520, 440, 350, 60],    ; από y450 h65
        [520, 515, 350, 60]     ; από y530 h65
    ]
    
    Loop 4 {
        pos := positions[A_Index]
        MyGui["Option" . A_Index].Move(pos[1], pos[2], pos[3], pos[4])
    }
}

NormalizeCountryName(country) {
    normalizeMap := Map(
        "Bolivia, Plurinational State of", "Bolivia",
        "Congo, The Democratic Republic of the", "Congo (Democratic Republic)",
        "Congo", "Congo (Republic)",
        "Iran, Islamic Republic of", "Iran",
        "Korea, Democratic People's Republic of", "North Korea",
        "Korea, Republic of", "South Korea",
        "Lao People's Democratic Republic", "Laos",
        "Cabo Verde", "Cape Verde",
        "Cote d'Ivoire", "Ivory Coast",
        "Syrian Arab Republic", "Syria",
        "Tanzania, United Republic of", "Tanzania",
        "Venezuela, Bolivarian Republic of", "Venezuela",
        "Viet Nam", "Vietnam",
        "Holy See (Vatican City State)", "Vatican City",
        "Timor-Leste", "East Timor",
        "Eswatini", "Eswatini (Swaziland)",
        "Brunei Darussalam", "Brunei",
        "Moldova, Republic of", "Moldova",
        "Taiwan, Province of China", "Taiwan",
        "Russian Federation", "Russia",
        "Palestine, State of", "Palestine",
        "Republic of Kosovo", "Kosovo",
        "Micronesia, Federated States of", "Micronesia"
    )
    Return normalizeMap.Has(country) ? normalizeMap[country] : country
}

OnPlayerNameChange(*) {
    Global CurrentPlayer
    rawName := PlayerName.Value
    
    rawName := StrReplace(rawName, "=", "")
    rawName := StrReplace(rawName, "`n", "")
    rawName := StrReplace(rawName, "`r", "")
    rawName := StrReplace(rawName, "[", "")
    rawName := StrReplace(rawName, "]", "")
    rawName := Trim(rawName)
    
    If (StrLen(rawName) > Config.MAX_PLAYER_NAME_LENGTH)
        rawName := SubStr(rawName, 1, Config.MAX_PLAYER_NAME_LENGTH)
    
    If (rawName != PlayerName.Value)
        PlayerName.Value := rawName
    
    CurrentPlayer := (rawName = "") ? "Player" : rawName
}

ValidateResources() {
    Global MissingFlags, MissingShapes, Countries
    MissingFlags := []
    MissingShapes := []
    
    flagCount := 0
    shapeCount := 0
    
    If !FileExist(Resources.FLAGS_DIR) {
        ShowWarning("Missing Resources", "'" . Resources.FLAGS_DIR . "' folder not found!")
        Return
    }
    
    If !FileExist(Resources.SHAPES_DIR) {
        ShowWarning("Missing Resources", "'" . Resources.SHAPES_DIR . "' folder not found!")
        Return
    }
    
    For country in Countries {
        If !FileExist(Resources.GetFlagPath(country))
            MissingFlags.Push(country)
        Else
            flagCount++
            
        If !FileExist(Resources.GetShapePath(country))
            MissingShapes.Push(country)
        Else
            shapeCount++
    }
    
    If (MissingFlags.Length > 0 || MissingShapes.Length > 0) {
        message := "⚠️ RESOURCE VALIDATION`n`n"
        message .= "✅ Flags: " . flagCount . "/" . Countries.Length . "`n"
        message .= "✅ Shapes: " . shapeCount . "/" . Countries.Length
        ShowSuccess("Resource Check", message)
    }
}

CountryHasResources(country, quizType) {
    Global MissingFlags, MissingShapes
    
    If (quizType = "Flags" && HasValue(MissingFlags, country))
        Return false
    If (quizType = "Countries Shapes" && HasValue(MissingShapes, country))
        Return false
    
    Return true
}

FormatCountryName(countryName) {
    If (StrLen(countryName) > Config.MAX_COUNTRY_NAME_DISPLAY) {
        shortName := SubStr(countryName, 1, Config.MAX_COUNTRY_NAME_DISPLAY)
        Return shortName . "..."
    }
    Return countryName
}

ShuffleArray(arr) {
    shuffled := arr.Clone()
    Loop shuffled.Length {
        r := Random(A_Index, shuffled.Length)
        temp := shuffled[A_Index]
        shuffled[A_Index] := shuffled[r]
        shuffled[r] := temp
    }
    Return shuffled
}

HasValue(arr, value) {
    For index, arrValue in arr {
        If (arrValue = value)
            Return true
    }
    Return false
}

QuickSortScores(arr) {
    If (arr.Length <= 1)
        Return arr
    
    pivot := arr[1].score
    left := []
    right := []
    
    Loop arr.Length {
        If (A_Index = 1)
            Continue
        If (arr[A_Index].score >= pivot)
            left.Push(arr[A_Index])
        Else
            right.Push(arr[A_Index])
    }
    
    result := QuickSortScores(left)
    result.Push(arr[1])
    For item in QuickSortScores(right)
        result.Push(item)
    
    Return result
}

CleanupOnExit(ExitReason, ExitCode) {
    SetTimer UpdateTimer, 0
    SetTimer AutoNextQuestion, 0
    
    Try {
        SaveHighScores()
        Stats.Save()
    }
    
    Return 0
}

; ═══════════════════════════════════════════════════════════════════════════════
; EVENT HANDLERS
; ═══════════════════════════════════════════════════════════════════════════════

OnQuizTypeChange(*) {
    Global QuizType, MaxQuestions
    If MyGui["FlagsQuiz"].Value
        QuizType := "Flags"
    Else If MyGui["ShapesQuiz"].Value
        QuizType := "Countries Shapes"
    Else If MyGui["CountryCapitalQuiz"].Value
        QuizType := "Country By Capital"
    Else If MyGui["CapitalCountryQuiz"].Value
        QuizType := "Capital By Country"
    Else If MyGui["ChallengeQuiz"].Value {
        QuizType := "Challenge"
        MaxQuestions := Config.CHALLENGE_TOTAL_QUESTIONS
        MyGui["Questions10"].Value := 0
        MyGui["Questions25"].Value := 0
        MyGui["Questions50"].Value := 0
        MyGui["QuestionsAll"].Value := 0
    }
}

OnQuestionsChange(*) {
    Global MaxQuestions, QuizType
    If (QuizType = "Challenge")
        Return
        
    If MyGui["Questions10"].Value
        MaxQuestions := 10
    Else If MyGui["Questions25"].Value
        MaxQuestions := 25
    Else If MyGui["Questions50"].Value
        MaxQuestions := 50
    Else If MyGui["QuestionsAll"].Value
        MaxQuestions := Countries.Length
}

; ═══════════════════════════════════════════════════════════════════════════════
; HIGH SCORE FUNCTIONS - FIXED VERSION
; ═══════════════════════════════════════════════════════════════════════════════

LoadHighScores() {
    Global HighScores
    HighScores := Map()
    
    HighScores["Flags"] := Map()
    HighScores["Countries Shapes"] := Map()
    HighScores["Country By Capital"] := Map()
    HighScores["Capital By Country"] := Map()
    HighScores["Challenge"] := Map()
    
    If FileExist(Resources.HIGHSCORES_FILE) {
        Try {
            For quizType in HighScores {
                sectionData := IniRead(Resources.HIGHSCORES_FILE, quizType)
                If (sectionData != "ERROR") {
                    lines := StrSplit(sectionData, "`n")
                    For line in lines {
                        line := Trim(line)
                        If (line != "" && InStr(line, "=")) {
                            parts := StrSplit(line, "=")
                            If (parts.Length >= 2) {
                                playerName := Trim(parts[1])
                                playerScore := Integer(Trim(parts[2]))
                                If (playerName != "" && playerScore != "")
                                    HighScores[quizType][playerName] := playerScore
                            }
                        }
                    }
                }
            }
        } Catch as e {
            ; Silent fail on error
        }
    }
}

SaveHighScores() {
    Global HighScores
    Try {
        ; Delete existing file to start fresh
        If FileExist(Resources.HIGHSCORES_FILE)
            FileDelete(Resources.HIGHSCORES_FILE)
        
        ; Write each score individually
        For quizType, scores in HighScores {
            For player, score in scores {
                IniWrite(score, Resources.HIGHSCORES_FILE, quizType, player)
            }
        }
    } Catch as e {
        ShowError("Save Error", "Failed to save high scores: " . e.Message)
    }
}

FormatHighScores() {
    Global HighScores
    text := ""
    
    For quizType, scores in HighScores {
        text .= "┌─ " . quizType . " ─┐`n"
        
        sortedScores := []
        For player, score in scores
            sortedScores.Push({player: player, score: score})
        
        sortedScores := QuickSortScores(sortedScores)
        
        count := 0
        For entry in sortedScores {
            If (count >= 5)
                Break
            text .= " " . entry.player . ": " . entry.score . "`n"
            count++
        }
        
        If (sortedScores.Length = 0)
            text .= " No scores yet`n"
        text .= "`n"
    }
    Return text
}

UpdateHighScores(quizType, score, player) {
    Global HighScores
    If !HighScores.Has(quizType)
        HighScores[quizType] := Map()
    
    If !HighScores[quizType].Has(player) || score > HighScores[quizType][player] {
        HighScores[quizType][player] := score
        SaveHighScores()
    }
    
    HighScoresText.Value := FormatHighScores()
}

; ═══════════════════════════════════════════════════════════════════════════════
; TIMER FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════

StartTimer() {
    Global TimeLeft, TimerActive, QuestionStartTime
    TimeLeft := Difficulty.Current.timer
    TimerActive := true
    QuestionStartTime := A_TickCount
    SetTimer UpdateTimer, 1000
}

StopTimer() {
    Global TimerActive
    TimerActive := false
    SetTimer UpdateTimer, 0
}

UpdateTimer() {
    Global TimeLeft, TimerActive
    If (!TimerActive)
        Return
    
    TimeLeft--
    TimerText.Value := "⏱️ Time: " . TimeLeft . "s"
    
    If (TimeLeft <= 3) {
        TimerText.Opt("c" . Colors.TIMER_CRITICAL)
        Sounds.Tick()
    } Else If (TimeLeft <= 5) {
        TimerText.Opt("c" . Colors.TIMER_WARNING)
    } Else {
        TimerText.Opt("c" . Colors.TIMER_NORMAL)
    }
    
    If (TimeLeft <= 0) {
        StopTimer()
        TimeUp()
    }
}

TimeUp() {
    Global CurrentCountry, CurrentCapital, AnswerSelected, QuizType, CurrentStreak
    Global ShuffledOptions, ChallengeRound, ChallengeTypes
    
    ; Validate ShuffledOptions
    If (!IsObject(ShuffledOptions) || ShuffledOptions.Length < 4) {
        ; Invalid state, skip to next question
        SetTimer AutoNextQuestion, Config.NEXT_QUESTION_DELAY
        Return
    }
    
    AnswerSelected := true
    CurrentStreak := 0
    UpdateStreakDisplay()
    
    Stats.RecordAnswer(false, Difficulty.Current.timer)
    Sounds.Wrong()
    
    ; Determine current quiz type
    If (QuizType = "Challenge") {
        CurrentQuizType := ChallengeTypes[ChallengeRound]
    } Else {
        CurrentQuizType := QuizType
    }
    
    If (CurrentQuizType = "Country By Capital") {
        normalizedCountry := NormalizeCountryName(CurrentCountry)
        If CountriesGreek.Has(normalizedCountry) {
            correctAnswer := CountriesGreek[normalizedCountry]
            ResultText.Opt("c" . Colors.ERROR)
            ResultText.Value := "✗ WRONG! The correct answer is: " . correctAnswer
        } Else {
            ResultText.Opt("c" . Colors.ERROR)
            ResultText.Value := "✗ WRONG! Time's up!"
        }
    } Else If (CurrentQuizType = "Capital By Country") {
        correctAnswer := ""
        For country, capital in CountriesGreek {
            If (capital = CurrentCapital) {
                correctAnswer := country
                Break
            }
        }
        ResultText.Opt("c" . Colors.ERROR)
        ResultText.Value := "✗ WRONG! The correct answer is: " . correctAnswer
    } Else {
        ResultText.Opt("c" . Colors.ERROR)
        ResultText.Value := "✗ WRONG! Time's up!"
    }
    
    Loop 4 {
        MyGui["Option" . A_Index].Enabled := false
    }
    SetTimer AutoNextQuestion, Config.NEXT_QUESTION_DELAY
}

; ═══════════════════════════════════════════════════════════════════════════════
; GAME CONTROL FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════

MainMenu(*) {
    Global GameStarted, Score, TotalQuestions, TimerActive, ChallengeRound
    Global CurrentCountry, CurrentCapital, CurrentStreak, BestStreakThisGame
    Global IsProcessingQuestion  ; <-- NEW
    
    StopTimer()
    SetTimer AutoNextQuestion, 0  ; <-- Cancel any pending timers
    
    IsProcessingQuestion := false  ; <-- Reset flag
    GameStarted := false
    ChallengeRound := 0
    CurrentCountry := ""
    CurrentCapital := ""
    CurrentStreak := 0
    BestStreakThisGame := 0
    
    ; Show menu elements
    FlagsQuiz.Visible := true
    ShapesQuiz.Visible := true
    CountryCapitalQuiz.Visible := true
    CapitalCountryQuiz.Visible := true
    ChallengeQuiz.Visible := true
    DifficultyText.Visible := true
    EasyDiff.Visible := true
    NormalDiff.Visible := true
    HardDiff.Visible := true
    ExpertDiff.Visible := true
    PlayerNameText.Visible := true
    PlayerName.Visible := true
    QuestionsText.Visible := true
    Questions10.Visible := true
    Questions25.Visible := true
    Questions50.Visible := true
    QuestionsAll.Visible := true
    StartButton.Visible := true
    HighScoresTitle.Visible := true
    HighScoresText.Visible := true
    SelectQuizTypeText.Visible := true
    StatsBtn.Visible := true
    DarkModeBtn.Visible := true
    SoundBtn.Visible := true
    
    ; Hide game elements
    QuestionText.Visible := false
    StreakText.Visible := false
    FlagPic.Visible := false
    ShapePic.Visible := false
    Option1Btn.Visible := false
    Option2Btn.Visible := false
    Option3Btn.Visible := false
    Option4Btn.Visible := false
    TimerText.Visible := false
    HintBtn.Visible := false
    ResultText.Visible := false
    ScoreInfoText.Visible := false
    ProgressBar.Visible := false
    PlayAgainBtn.Visible := false
    MainMenuBtn.Visible := false
    
    Score := 0
    TotalQuestions := 0
}

StartQuiz(*) {
    Global MaxQuestions, GameStarted, Score, TotalQuestions, QuizType, ChallengeRound
    Global CurrentStreak, BestStreakThisGame, HintsLeft
    
    GameStarted := true
    Score := 0
    TotalQuestions := 0
    ChallengeRound := 0
    CurrentStreak := 0
    BestStreakThisGame := 0
    HintsLeft := Difficulty.Current.hints
    
    Stats.StartTime := A_TickCount
    
    If (QuizType = "Challenge") {
        MaxQuestions := Config.CHALLENGE_TOTAL_QUESTIONS
    }
    
    ; Hide menu
    FlagsQuiz.Visible := false
    ShapesQuiz.Visible := false
    CountryCapitalQuiz.Visible := false
    CapitalCountryQuiz.Visible := false
    ChallengeQuiz.Visible := false
    DifficultyText.Visible := false
    EasyDiff.Visible := false
    NormalDiff.Visible := false
    HardDiff.Visible := false
    ExpertDiff.Visible := false
    PlayerNameText.Visible := false
    PlayerName.Visible := false
    QuestionsText.Visible := false
    Questions10.Visible := false
    Questions25.Visible := false
    Questions50.Visible := false
    QuestionsAll.Visible := false
    StartButton.Visible := false
    HighScoresTitle.Visible := false
    HighScoresText.Visible := false
    SelectQuizTypeText.Visible := false
    StatsBtn.Visible := false
    DarkModeBtn.Visible := false
    SoundBtn.Visible := false
    
    ; Show game UI
    QuestionText.Visible := true
    StreakText.Visible := true
    ResultText.Visible := true
    ScoreInfoText.Visible := true
    ProgressBar.Visible := true
    TimerText.Visible := true
    MainMenuBtn.Visible := true
    
    If (HintsLeft > 0)
        HintBtn.Visible := true
    HintBtn.Text := "💡 HINT (" . HintsLeft . ")"
    
    If (QuizType = "Flags") {
        QuestionText.Value := "Find the country by its flag:"
        FlagPic.Visible := true
        Option1Btn.Visible := true
        Option2Btn.Visible := true
        Option3Btn.Visible := true
        Option4Btn.Visible := true
        ShapePic.Visible := false
        PositionQuizButtons()
    } Else If (QuizType = "Countries Shapes") {
        QuestionText.Value := "Find the country by its shape:"
        ShapePic.Visible := true
        Option1Btn.Visible := true
        Option2Btn.Visible := true
        Option3Btn.Visible := true
        Option4Btn.Visible := true
        FlagPic.Visible := false
        PositionQuizButtons()
        ShapePic.Move(420, 170, 250, 250)  ; από y180 → y170
    } Else If (QuizType = "Country By Capital" || QuizType = "Capital By Country") {
        FlagPic.Visible := false
        ShapePic.Visible := false
        Option1Btn.Visible := true
        Option2Btn.Visible := true
        Option3Btn.Visible := true
        Option4Btn.Visible := true
        PositionQuizButtons()
    } Else If (QuizType = "Challenge") {
        QuestionText.Value := "Challenge: Flags"
        FlagPic.Visible := true
        Option1Btn.Visible := true
        Option2Btn.Visible := true
        Option3Btn.Visible := true
        Option4Btn.Visible := true
        ShapePic.Visible := false
        ChallengeRound := 1
        MaxQuestions := Config.CHALLENGE_TOTAL_QUESTIONS
        PositionQuizButtons()
    }
    
    NextQuestion()
}

PlayAgain(*) {
    Global GameStarted, Score, TotalQuestions, ChallengeRound
    Global CurrentStreak, BestStreakThisGame, HintsLeft
    
    GameStarted := true
    Score := 0
    TotalQuestions := 0
    ChallengeRound := 0
    CurrentStreak := 0
    BestStreakThisGame := 0
    HintsLeft := Difficulty.Current.hints
    HintBtn.Text := "💡 HINT (" . HintsLeft . ")"
    
    Stats.StartTime := A_TickCount
    PlayAgainBtn.Visible := false
    NextQuestion()
}

NextQuestion() {
    Global AnswerSelected, TotalQuestions, MaxQuestions, Score, GameStarted
    Global CurrentCountry, CurrentCapital, QuizType, ShuffledOptions, ChallengeRound, ChallengeTypes
    Global IsProcessingQuestion  ; <-- NEW
    
    ; Prevent recursive calls - but allow timer-based retries
    If (IsProcessingQuestion) {
        Return
    }
    IsProcessingQuestion := true
    
    ; Initialize ShuffledOptions if not exists
    If (!IsObject(ShuffledOptions))
        ShuffledOptions := []
    
    If (AnswerSelected) {
        AnswerSelected := false
        SetTimer AutoNextQuestion, 0
    }
    
    StopTimer()
    ResultText.Value := ""
    
    ; Re-enable hint button
    If (HintsLeft > 0)
        HintBtn.Enabled := true
    
    If (TotalQuestions >= MaxQuestions) {
        IsProcessingQuestion := false  ; <-- Reset flag
        percent := Round((Score/MaxQuestions)*100)
        UpdateHighScores(QuizType, Score, CurrentPlayer)
        Stats.RecordGame(QuizType)
        Stats.RecordStreak(BestStreakThisGame)
        
        Sounds.Complete()
        
        message := ""
        If (percent >= 80)
            message := "🎉 Excellent performance! Congratulations!`n`n"
        Else If (percent >= 60)
            message := "👍 Good performance!`n`n"
        Else If (percent >= 40)
            message := "📚 Average performance. You can do better!`n`n"
        Else
            message := "💪 Try again for a better score!`n`n"
        
        message .= "Score: " . Score . "/" . MaxQuestions . " (" . percent . "%)`n"
        message .= "Best Streak: " . BestStreakThisGame . "`n"
        message .= "Difficulty: " . Difficulty.Current.name
        
        MsgBox(message, "Quiz Complete", 64)
        GameStarted := false
        PlayAgainBtn.Visible := true
        Return
    }
    
    CurrentCountry := ""
    CurrentCapital := ""
    
    If (QuizType = "Challenge") {
        ChallengeRound := Floor(TotalQuestions / Config.QUESTIONS_PER_ROUND) + 1
        
        If (ChallengeRound > ChallengeTypes.Length)
            ChallengeRound := ChallengeTypes.Length
        
        CurrentQuizType := ChallengeTypes[ChallengeRound]
        
        If (CurrentQuizType = "Flags") {
            FlagPic.Visible := true
            ShapePic.Visible := false
            QuestionText.Value := "Challenge: Flags (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        } Else If (CurrentQuizType = "Countries Shapes") {
            FlagPic.Visible := false
            ShapePic.Visible := true
            QuestionText.Value := "Challenge: Shapes (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        } Else If (CurrentQuizType = "Country By Capital") {
            FlagPic.Visible := false
            ShapePic.Visible := false
            QuestionText.Value := "Challenge: Country → Capital (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        } Else If (CurrentQuizType = "Capital By Country") {
            FlagPic.Visible := false
            ShapePic.Visible := false
            QuestionText.Value := "Challenge: Capital → Country (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        }
    } Else {
        CurrentQuizType := QuizType
    }
    
    ProgressPos := (TotalQuestions/MaxQuestions)*100
    ProgressBar.Value := ProgressPos
    
    Loop 4 {
        MyGui["Option" . A_Index].Enabled := true
        buttonColors := [Colors.PRIMARY_BLUE, Colors.AMBER, Colors.GREEN, Colors.VIOLET]
        MyGui["Option" . A_Index].Opt("Background" . buttonColors[A_Index])
    }
    
    If (CurrentQuizType = "Flags" || CurrentQuizType = "Countries Shapes") {
        ; Build list of valid countries ONCE
        validCountries := []
        For country in Countries {
            If CountryHasResources(country, CurrentQuizType) {
                validCountries.Push(country)
            }
        }
        
        ; Check if we have enough countries
        If (validCountries.Length < 4) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Resource Error", "Not enough countries with required resources (need 4, found " . validCountries.Length . ")")
            MainMenu()
            Return
        }
        
        ; Select random country from valid list
        randIndex := Random(1, validCountries.Length)
        CurrentCountry := validCountries[randIndex]
        
        If (CurrentQuizType = "Flags") {
            flagPath := Resources.GetFlagPath(CurrentCountry)
            If FileExist(flagPath) {
                Try {
                    FlagPic.Value := flagPath
                } Catch as e {
                    IsProcessingQuestion := false  ; <-- Reset flag before recursive call
                    ShowError("Image Error", "Failed to load flag: " . e.Message)
                    ; Use SetTimer instead of direct recursion
                    SetTimer(() => NextQuestion(), -100)
                    Return
                }
            } Else {
                IsProcessingQuestion := false  ; <-- Reset flag
                SetTimer(() => NextQuestion(), -100)
                Return
            }
            
            If (QuizType != "Challenge")
                QuestionText.Value := "Find the country by its flag: (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        } Else If (CurrentQuizType = "Countries Shapes") {
            shapePath := Resources.GetShapePath(CurrentCountry)
            If FileExist(shapePath) {
                Try {
                    ShapePic.Value := shapePath
                } Catch as e {
                    IsProcessingQuestion := false  ; <-- Reset flag
                    ShowError("Image Error", "Failed to load shape: " . e.Message)
                    SetTimer(() => NextQuestion(), -100)
                    Return
                }
            } Else {
                IsProcessingQuestion := false  ; <-- Reset flag
                SetTimer(() => NextQuestion(), -100)
                Return
            }
            
            If (QuizType != "Challenge")
                QuestionText.Value := "Find the country by its shape: (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        }
        
        ; Build wrong options from valid countries
        Options := [CurrentCountry]
        availableCountries := validCountries.Clone()
        
        ; Remove current country from available options
        Loop availableCountries.Length {
            If (availableCountries[A_Index] = CurrentCountry) {
                availableCountries.RemoveAt(A_Index)
                Break
            }
        }
        
        Loop 3 {
            If (availableCountries.Length = 0)
                Break
            wrongIndex := Random(1, availableCountries.Length)
            wrongCountry := availableCountries[wrongIndex]
            Options.Push(wrongCountry)
            availableCountries.RemoveAt(wrongIndex)
        }
        
        ; Ensure we have 4 options
        If (Options.Length < 4) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "Not enough valid countries for options")
            MainMenu()
            Return
        }
        
        ShuffledOptions := ShuffleArray(Options)
        Loop 4 {
            country := ShuffledOptions[A_Index]
            formattedCountry := FormatCountryName(country)
            MyGui["Option" . A_Index].Text := formattedCountry
        }
        
    } Else If (CurrentQuizType = "Country By Capital") {
        countryKeys := []
        For country, capital in CountriesGreek
            countryKeys.Push(country)
        
        If (countryKeys.Length = 0) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "No countries found!")
            MainMenu()
            Return
        }
        
        attempts := 0
        validCountry := false
        
        While (!validCountry && attempts < 100) {
            randIndex := Random(1, countryKeys.Length)
            testCountry := countryKeys[randIndex]
            
            For country in Countries {
                normalizedCountry := NormalizeCountryName(country)
                If (normalizedCountry = testCountry) {
                    CurrentCountry := country
                    CurrentCapital := CountriesGreek[testCountry]
                    validCountry := true
                    Break
                }
            }
            attempts++
        }
        
        If (!validCountry) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "Could not find valid country!")
            MainMenu()
            Return
        }
        
        QuestionText.Value := "What is the capital of " . CurrentCountry . "? (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        
        Options := [CurrentCapital]
        capitalList := []
        For country, capital in CountriesGreek {
            If (!HasValue(capitalList, capital))
                capitalList.Push(capital)
        }
        
        If (capitalList.Length < 4) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "Not enough capitals!")
            MainMenu()
            Return
        }
        
        Loop 3 {
            attempts := 0
            wrongCapital := ""
            While (attempts < 100) {
                wrongIndex := Random(1, capitalList.Length)
                wrongCapital := capitalList[wrongIndex]
                If (wrongCapital != CurrentCapital && !HasValue(Options, wrongCapital))
                    Break
                attempts++
            }
            If (wrongCapital != "" && wrongCapital != CurrentCapital)
                Options.Push(wrongCapital)
        }
        
        ShuffledOptions := ShuffleArray(Options)
        Loop 4 {
            capital := ShuffledOptions[A_Index]
            MyGui["Option" . A_Index].Text := capital
        }
        
    } Else If (CurrentQuizType = "Capital By Country") {
        capitalList := []
        countryList := []
        For country, capital in CountriesGreek {
            capitalList.Push(capital)
            countryList.Push(country)
        }
        
        If (capitalList.Length = 0) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "No capitals found!")
            MainMenu()
            Return
        }
        
        randIndex := Random(1, capitalList.Length)
        CurrentCapital := capitalList[randIndex]
        
        CurrentCountry := ""
        For country, capital in CountriesGreek {
            If (capital = CurrentCapital) {
                CurrentCountry := country
                Break
            }
        }
        
        If (CurrentCountry = "") {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "No country found for capital!")
            MainMenu()
            Return
        }
        
        QuestionText.Value := "Which country has the capital " . CurrentCapital . "? (" . (TotalQuestions + 1) . "/" . MaxQuestions . ")"
        
        Options := [CurrentCountry]
        
        If (countryList.Length < 4) {
            IsProcessingQuestion := false  ; <-- Reset flag
            ShowError("Data Error", "Not enough countries!")
            MainMenu()
            Return
        }
        
        Loop 3 {
            attempts := 0
            wrongCountry := ""
            While (attempts < 100) {
                wrongIndex := Random(1, countryList.Length)
                wrongCountry := countryList[wrongIndex]
                If (wrongCountry != CurrentCountry && !HasValue(Options, wrongCountry))
                    Break
                attempts++
            }
            If (wrongCountry != "" && wrongCountry != CurrentCountry)
                Options.Push(wrongCountry)
        }
        
        ShuffledOptions := ShuffleArray(Options)
        Loop 4 {
            country := ShuffledOptions[A_Index]
            formattedCountry := FormatCountryName(country)
            MyGui["Option" . A_Index].Text := formattedCountry
        }
    }
    
    TotalQuestions++
    ScoreInfoText.Value := "Score: " . Score . "/" . TotalQuestions
    UpdateStreakDisplay()
    StartTimer()
    
    IsProcessingQuestion := false  ; <-- Reset flag at end
}

; ═══════════════════════════════════════════════════════════════════════════════
; ANSWER CHECKING
; ═══════════════════════════════════════════════════════════════════════════════

Option1(*) => CheckAnswer(1)
Option2(*) => CheckAnswer(2)
Option3(*) => CheckAnswer(3)
Option4(*) => CheckAnswer(4)

CheckAnswer(optionIndex) {
    Global CurrentCountry, CurrentCapital, Score, AnswerSelected, QuizType
    Global ShuffledOptions, ChallengeRound, ChallengeTypes, CurrentStreak, BestStreakThisGame
    Global QuestionStartTime
    
    ; Validate ShuffledOptions exists and has content
    If (!IsObject(ShuffledOptions) || ShuffledOptions.Length < 4) {
        Return  ; Safety check - invalid state
    }
    
    If (AnswerSelected)
        Return
    
    AnswerSelected := true
    StopTimer()
    
    ; Calculate time taken
    timeToAnswer := (A_TickCount - QuestionStartTime) / 1000
    
    ; Disable hint button
    HintBtn.Enabled := false
    
    If (QuizType = "Challenge") {
        CurrentQuizType := ChallengeTypes[ChallengeRound]
    } Else {
        CurrentQuizType := QuizType
    }
    
    selectedAnswer := ShuffledOptions[optionIndex]
    correct := false
    
    If (CurrentQuizType = "Flags" || CurrentQuizType = "Countries Shapes") {
        correct := (selectedAnswer = CurrentCountry)
    } Else If (CurrentQuizType = "Country By Capital") {
        correct := (selectedAnswer = CurrentCapital)
    } Else If (CurrentQuizType = "Capital By Country") {
        normalizedSelected := NormalizeCountryName(selectedAnswer)
        correct := (normalizedSelected = CurrentCountry || selectedAnswer = CurrentCountry)
    }
    
    If (correct) {
        ; Success!
        CurrentStreak++
        If (CurrentStreak > BestStreakThisGame)
            BestStreakThisGame := CurrentStreak
        
        ; Calculate score with streak bonus
        bonus := 0
        If (CurrentStreak >= 10)
            bonus := 5
        Else If (CurrentStreak >= 5)
            bonus := 2
        
        Score += (1 + bonus)
        
        Stats.RecordAnswer(true, timeToAnswer)
        Sounds.Correct()
        
        If (CurrentStreak >= 5)
            Sounds.Streak()
        
        ResultText.Opt("c" . Colors.SUCCESS)
        If (bonus > 0)
            ResultText.Value := "✅ CORRECT! 🔥 STREAK x" . CurrentStreak . " (+" . bonus . " bonus!)"
        Else
            ResultText.Value := "✅ CORRECT!"
        
        MyGui["Option" . optionIndex].Opt("Background" . Colors.SUCCESS)
        
    } Else {
        ; Wrong answer
        CurrentStreak := 0
        
        Stats.RecordAnswer(false, timeToAnswer)
        Sounds.Wrong()
        
        ; Apply penalty in Hard/Expert mode
        If (Difficulty.Current.penalty && Score > 0)
            Score--
        
        ResultText.Opt("c" . Colors.ERROR)
        MyGui["Option" . optionIndex].Opt("Background" . Colors.ERROR)
        
        ; Highlight correct answer
        Loop 4 {
            If (CurrentQuizType = "Flags" || CurrentQuizType = "Countries Shapes" || CurrentQuizType = "Capital By Country") {
                testAnswer := ShuffledOptions[A_Index]
                normalizedTest := NormalizeCountryName(testAnswer)
                If (normalizedTest = CurrentCountry || testAnswer = CurrentCountry) {
                    MyGui["Option" . A_Index].Opt("Background" . Colors.SUCCESS)
                    Break
                }
            } Else If (CurrentQuizType = "Country By Capital") {
                If (ShuffledOptions[A_Index] = CurrentCapital) {
                    MyGui["Option" . A_Index].Opt("Background" . Colors.SUCCESS)
                    Break
                }
            }
        }
        
        If (CurrentQuizType = "Country By Capital") {
            ResultText.Value := "✗ WRONG! Correct: " . CurrentCapital
        } Else If (CurrentQuizType = "Capital By Country") {
            ResultText.Value := "✗ WRONG! Correct: " . CurrentCountry
        } Else {
            ResultText.Value := "✗ WRONG! Correct: " . CurrentCountry
        }
        
        If (Difficulty.Current.penalty)
            ResultText.Value .= " (-1 penalty)"
    }
    
    UpdateStreakDisplay()
    
    Loop 4 {
        MyGui["Option" . A_Index].Enabled := false
    }
    
    SetTimer AutoNextQuestion, Config.NEXT_QUESTION_DELAY
}
    

AutoNextQuestion() {
    Global IsProcessingQuestion
    
    ; Cancel timer first
    SetTimer AutoNextQuestion, 0
    
    ; Only proceed if not already processing
    If (!IsProcessingQuestion) {
        NextQuestion()
    }
}