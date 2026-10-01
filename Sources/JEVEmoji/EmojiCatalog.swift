import Foundation

struct EmojiItem: Identifiable, Hashable {
    let emoji: String
    let name: String
    let keywords: [String]
    let category: String
    let popularity: Int

    var id: String { emoji }
    var searchableText: String { ([name, category] + keywords).joined(separator: " ").lowercased() }
}

enum EmojiCatalog {
    static var popular: [EmojiItem] {
        Array(items.sorted { $0.popularity > $1.popularity }.prefix(10))
    }

    static let items: [EmojiItem] = [
        .init(emoji: "😀", name: "활짝 웃는 얼굴", keywords: ["happy", "웃음", "기쁨", "행복", "좋아", "즐거움", "미소", "smile", "grin"], category: "얼굴", popularity: 100),
        .init(emoji: "😂", name: "기뻐서 우는 얼굴", keywords: ["lol", "웃겨", "빵터짐", "폭소", "재미", "funny", "laugh", "tears of joy"], category: "얼굴", popularity: 99),
        .init(emoji: "🥹", name: "감동받은 얼굴", keywords: ["감동", "울컥", "고마워", "감사", "뭉클", "감격", "touched", "grateful", "please"], category: "얼굴", popularity: 96),
        .init(emoji: "🥰", name: "하트와 미소", keywords: ["사랑", "애정", "좋아해", "설렘", "행복", "따뜻", "love", "adore", "crush"], category: "얼굴", popularity: 95),
        .init(emoji: "😍", name: "하트 눈", keywords: ["사랑", "최고", "예뻐", "멋져", "반함", "love", "beautiful", "heart eyes"], category: "얼굴", popularity: 94),
        .init(emoji: "😊", name: "수줍은 미소", keywords: ["기분좋아", "미소", "고마워", "수줍", "친절", "smile", "blush", "nice"], category: "얼굴", popularity: 93),
        .init(emoji: "😉", name: "윙크", keywords: ["장난", "농담", "알지", "비밀", "wink", "joke", "playful"], category: "얼굴", popularity: 80),
        .init(emoji: "😎", name: "선글라스", keywords: ["멋져", "쿨", "여유", "자신감", "여름", "cool", "confident", "sunglasses"], category: "얼굴", popularity: 82),
        .init(emoji: "🤔", name: "생각하는 얼굴", keywords: ["고민", "생각", "궁금", "질문", "검토", "의문", "think", "wonder", "hmm"], category: "얼굴", popularity: 92),
        .init(emoji: "🫡", name: "경례", keywords: ["확인", "알겠습니다", "충성", "수고", "존경", "roger", "salute", "yes"], category: "얼굴", popularity: 75),
        .init(emoji: "🥳", name: "파티", keywords: ["축하", "생일", "파티", "성공", "기념", "환영", "celebrate", "birthday", "party"], category: "얼굴", popularity: 91),
        .init(emoji: "😅", name: "땀 흘리며 웃는 얼굴", keywords: ["머쓱", "민망", "휴", "아슬아슬", "다행", "awkward", "nervous", "relief"], category: "얼굴", popularity: 85),
        .init(emoji: "😭", name: "크게 우는 얼굴", keywords: ["슬퍼", "눈물", "감동", "힘들어", "보고싶어", "sad", "cry", "miss you"], category: "얼굴", popularity: 90),
        .init(emoji: "🥲", name: "웃으며 눈물", keywords: ["웃픈", "괜찮아", "감동", "고생", "복잡", "bittersweet", "trying", "tears"], category: "얼굴", popularity: 87),
        .init(emoji: "😢", name: "우는 얼굴", keywords: ["슬픔", "속상", "눈물", "아쉬워", "위로", "sad", "cry", "sorry"], category: "얼굴", popularity: 84),
        .init(emoji: "😮", name: "놀란 얼굴", keywords: ["놀라워", "헉", "대박", "충격", "새소식", "wow", "surprise", "shock"], category: "얼굴", popularity: 83),
        .init(emoji: "😱", name: "비명 지르는 얼굴", keywords: ["깜짝", "무서워", "충격", "놀람", "비상", "scared", "scream", "shock"], category: "얼굴", popularity: 81),
        .init(emoji: "😴", name: "잠자는 얼굴", keywords: ["졸려", "수면", "잘자", "피곤", "휴식", "sleep", "tired", "good night"], category: "얼굴", popularity: 82),
        .init(emoji: "🤩", name: "별 눈", keywords: ["신나", "대단해", "멋져", "기대", "팬", "starstruck", "amazing", "excited"], category: "얼굴", popularity: 79),
        .init(emoji: "😇", name: "천사", keywords: ["착해", "선행", "순수", "천사", "angel", "innocent", "good"], category: "얼굴", popularity: 73),
        .init(emoji: "🤗", name: "포옹", keywords: ["안아줘", "위로", "환영", "반가워", "응원", "hug", "welcome", "support"], category: "얼굴", popularity: 80),
        .init(emoji: "😋", name: "맛있어", keywords: ["맛있다", "먹방", "음식", "배고파", "맛집", "yummy", "delicious", "food"], category: "얼굴", popularity: 78),
        .init(emoji: "🤯", name: "머리 폭발", keywords: ["놀라워", "충격", "대박", "천재", "믿기지 않아", "mind blown", "wow", "shock"], category: "얼굴", popularity: 76),
        .init(emoji: "🙏", name: "두 손 모아", keywords: ["부탁", "기도", "감사", "고마워", "제발", "합장", "please", "pray", "thanks"], category: "손", popularity: 98),
        .init(emoji: "👏", name: "박수", keywords: ["잘했어", "축하", "수고", "응원", "칭찬", "bravo", "clap", "congrats"], category: "손", popularity: 97),
        .init(emoji: "👍", name: "엄지 척", keywords: ["좋아", "확인", "동의", "최고", "오케이", "좋습니다", "like", "yes", "good", "ok"], category: "손", popularity: 96),
        .init(emoji: "👎", name: "엄지 아래", keywords: ["싫어", "반대", "별로", "아니", "no", "dislike", "bad"], category: "손", popularity: 68),
        .init(emoji: "🫶", name: "하트 손", keywords: ["사랑", "고마워", "응원", "하트", "좋아해", "love", "heart", "support"], category: "손", popularity: 90),
        .init(emoji: "🤝", name: "악수", keywords: ["약속", "협력", "합의", "환영", "함께", "deal", "partnership", "agreement"], category: "손", popularity: 78),
        .init(emoji: "💪", name: "근육", keywords: ["힘내", "파이팅", "운동", "강해", "응원", "strong", "fight", "gym", "workout"], category: "손", popularity: 88),
        .init(emoji: "✌️", name: "브이", keywords: ["브이", "평화", "승리", "사진", "peace", "victory", "photo"], category: "손", popularity: 77),
        .init(emoji: "🤞", name: "행운 빌기", keywords: ["행운", "잘되길", "제발", "기대", "luck", "hope", "fingers crossed"], category: "손", popularity: 75),
        .init(emoji: "🫰", name: "손가락 하트", keywords: ["사랑", "하트", "귀여워", "한국", "좋아해", "finger heart", "love", "korea"], category: "손", popularity: 83),
        .init(emoji: "👋", name: "손 흔들기", keywords: ["안녕", "인사", "잘가", "반가워", "hello", "bye", "wave"], category: "손", popularity: 81),
        .init(emoji: "❤️", name: "빨간 하트", keywords: ["사랑", "하트", "좋아해", "연애", "감사", "love", "heart", "romance"], category: "하트", popularity: 100),
        .init(emoji: "🧡", name: "주황 하트", keywords: ["사랑", "하트", "따뜻", "친구", "응원", "love", "heart", "warm"], category: "하트", popularity: 75),
        .init(emoji: "💛", name: "노란 하트", keywords: ["사랑", "우정", "행복", "햇살", "기쁨", "friendship", "sunshine", "joy"], category: "하트", popularity: 77),
        .init(emoji: "💚", name: "초록 하트", keywords: ["자연", "건강", "환경", "사랑", "초록", "nature", "health", "green"], category: "하트", popularity: 70),
        .init(emoji: "💙", name: "파란 하트", keywords: ["사랑", "우정", "신뢰", "바다", "하늘", "trust", "ocean", "blue"], category: "하트", popularity: 80),
        .init(emoji: "💜", name: "보라 하트", keywords: ["사랑", "팬", "응원", "보라", "kpop", "purple", "love", "fan"], category: "하트", popularity: 79),
        .init(emoji: "🖤", name: "검은 하트", keywords: ["슬픔", "시크", "검정", "사랑", "black", "dark", "love"], category: "하트", popularity: 73),
        .init(emoji: "💕", name: "두 개의 하트", keywords: ["사랑", "설렘", "연애", "커플", "love", "couple", "romance"], category: "하트", popularity: 85),
        .init(emoji: "💔", name: "깨진 하트", keywords: ["이별", "실연", "슬픔", "아파", "breakup", "heartbreak", "sad"], category: "하트", popularity: 77),
        .init(emoji: "💖", name: "반짝이는 하트", keywords: ["사랑", "설렘", "예뻐", "반짝", "sparkling", "love", "cute"], category: "하트", popularity: 76),
        .init(emoji: "💯", name: "백 점", keywords: ["완벽", "최고", "정답", "합격", "인정", "perfect", "score", "100"], category: "기호", popularity: 89),
        .init(emoji: "✨", name: "반짝임", keywords: ["멋져", "예뻐", "새출발", "성공", "빛나다", "magic", "sparkles", "glow"], category: "기호", popularity: 94),
        .init(emoji: "🔥", name: "불꽃", keywords: ["대박", "핫해", "열정", "최고", "인기", "hot", "fire", "awesome"], category: "기호", popularity: 95),
        .init(emoji: "✅", name: "체크 표시", keywords: ["완료", "확인", "성공", "체크", "오케이", "done", "check", "complete"], category: "기호", popularity: 86),
        .init(emoji: "❌", name: "엑스 표시", keywords: ["실패", "취소", "아니", "틀림", "안돼", "wrong", "cancel", "no"], category: "기호", popularity: 72),
        .init(emoji: "💡", name: "전구", keywords: ["아이디어", "생각", "영감", "발견", "힌트", "idea", "inspiration", "light"], category: "기호", popularity: 85),
        .init(emoji: "🎉", name: "파티 폭죽", keywords: ["축하", "성공", "생일", "기념", "합격", "celebration", "party", "congrats"], category: "기호", popularity: 97),
        .init(emoji: "🎊", name: "색종이 공", keywords: ["축하", "파티", "기념", "성공", "celebrate", "confetti", "party"], category: "기호", popularity: 80),
        .init(emoji: "⭐️", name: "별", keywords: ["최고", "즐겨찾기", "좋아", "평가", "star", "favorite", "best"], category: "기호", popularity: 78),
        .init(emoji: "💤", name: "잠", keywords: ["졸려", "잠", "수면", "피곤", "취침", "sleep", "tired", "zzz"], category: "기호", popularity: 71),
        .init(emoji: "💬", name: "말풍선", keywords: ["대화", "메시지", "댓글", "채팅", "소통", "chat", "message", "comment"], category: "기호", popularity: 73),
        .init(emoji: "📌", name: "핀", keywords: ["중요", "공지", "메모", "저장", "고정", "important", "note", "pin"], category: "기호", popularity: 76),
        .init(emoji: "📣", name: "확성기", keywords: ["공지", "알림", "발표", "홍보", "안내", "announcement", "news", "shout"], category: "기호", popularity: 69),
        .init(emoji: "🧠", name: "뇌", keywords: ["공부", "생각", "똑똑", "아이디어", "집중", "brain", "study", "smart"], category: "기호", popularity: 80),
        .init(emoji: "🚀", name: "로켓", keywords: ["성공", "시작", "출시", "성장", "출발", "launch", "startup", "growth"], category: "물건", popularity: 91),
        .init(emoji: "🎂", name: "생일 케이크", keywords: ["생일", "축하", "기념일", "케이크", "birthday", "cake", "anniversary"], category: "물건", popularity: 87),
        .init(emoji: "🎁", name: "선물", keywords: ["선물", "축하", "생일", "고마워", "기념", "gift", "present", "surprise"], category: "물건", popularity: 82),
        .init(emoji: "📈", name: "상승 차트", keywords: ["성장", "성과", "증가", "성공", "투자", "growth", "increase", "progress"], category: "물건", popularity: 78),
        .init(emoji: "💻", name: "노트북", keywords: ["일", "업무", "컴퓨터", "개발", "재택", "work", "coding", "computer"], category: "물건", popularity: 82),
        .init(emoji: "📚", name: "책", keywords: ["공부", "독서", "책", "배움", "학교", "study", "reading", "learn"], category: "물건", popularity: 78),
        .init(emoji: "☕️", name: "커피", keywords: ["커피", "카페", "휴식", "출근", "아침", "cafe", "coffee", "break"], category: "음식", popularity: 90),
        .init(emoji: "🍰", name: "케이크 한 조각", keywords: ["디저트", "케이크", "카페", "맛있어", "달콤", "dessert", "cake", "sweet"], category: "음식", popularity: 74),
        .init(emoji: "🍕", name: "피자", keywords: ["음식", "저녁", "배고파", "야식", "pizza", "dinner", "hungry"], category: "음식", popularity: 75),
        .init(emoji: "🍻", name: "건배", keywords: ["술", "회식", "축하", "친구", "파티", "cheers", "beer", "party"], category: "음식", popularity: 77),
        .init(emoji: "🌸", name: "벚꽃", keywords: ["봄", "꽃", "예뻐", "벚꽃", "사랑", "spring", "flower", "cherry blossom"], category: "자연", popularity: 83),
        .init(emoji: "☀️", name: "해", keywords: ["날씨", "맑음", "여름", "좋은아침", "햇살", "sun", "sunny", "weather"], category: "자연", popularity: 79),
        .init(emoji: "🌈", name: "무지개", keywords: ["희망", "행복", "날씨", "비온뒤", "다양성", "hope", "rainbow", "pride"], category: "자연", popularity: 77),
        .init(emoji: "🌱", name: "새싹", keywords: ["시작", "성장", "자연", "응원", "새로운", "growth", "beginning", "plant"], category: "자연", popularity: 78),
        .init(emoji: "🐶", name: "강아지", keywords: ["반려동물", "귀여워", "멍멍이", "강아지", "dog", "puppy", "pet"], category: "동물", popularity: 82),
        .init(emoji: "🐱", name: "고양이", keywords: ["반려동물", "귀여워", "야옹", "고양이", "cat", "kitty", "pet"], category: "동물", popularity: 83),
        .init(emoji: "🧸", name: "곰 인형", keywords: ["귀여워", "선물", "포근", "위로", "테디베어", "cute", "teddy", "comfort"], category: "동물", popularity: 75),
        .init(emoji: "🏆", name: "우승 트로피", keywords: ["승리", "성공", "우승", "최고", "1등", "winner", "trophy", "champion"], category: "활동", popularity: 83),
        .init(emoji: "⚽️", name: "축구공", keywords: ["축구", "운동", "스포츠", "경기", "soccer", "football", "sports"], category: "활동", popularity: 71),
        .init(emoji: "✈️", name: "비행기", keywords: ["여행", "휴가", "출장", "출발", "공항", "travel", "flight", "vacation"], category: "활동", popularity: 81),
        .init(emoji: "🏠", name: "집", keywords: ["집", "재택", "가족", "부동산", "이사", "home", "house", "family"], category: "장소", popularity: 73),
        .init(emoji: "🌍", name: "지구", keywords: ["세계", "여행", "환경", "지구", "글로벌", "earth", "world", "environment"], category: "장소", popularity: 74),
        .init(emoji: "🚗", name: "자동차", keywords: ["차", "운전", "여행", "출근", "교통", "car", "drive", "traffic"], category: "장소", popularity: 71),
        .init(emoji: "🏥", name: "병원", keywords: ["병원", "건강", "아파", "진료", "의사", "hospital", "health", "doctor"], category: "장소", popularity: 67),
        .init(emoji: "📅", name: "달력", keywords: ["일정", "약속", "회의", "날짜", "캘린더", "schedule", "meeting", "date"], category: "물건", popularity: 75),
        .init(emoji: "⏰", name: "알람 시계", keywords: ["시간", "마감", "알람", "늦었어", "일정", "time", "deadline", "alarm"], category: "물건", popularity: 77),
        .init(emoji: "💸", name: "날아가는 돈", keywords: ["돈", "지출", "쇼핑", "월급", "비싸", "money", "spending", "shopping"], category: "물건", popularity: 72),
        .init(emoji: "🛍️", name: "쇼핑백", keywords: ["쇼핑", "구매", "선물", "패션", "shopping", "buy", "fashion"], category: "물건", popularity: 72),
        .init(emoji: "🥂", name: "샴페인 잔", keywords: ["축하", "건배", "성공", "기념일", "파티", "cheers", "celebrate", "toast"], category: "음식", popularity: 78)
    ]

}
