class Post {
  String author;
  String description;
  String email;
  List<String> likes;
  String name;
  String postId;
  String propic;
  String subjectTitle;
  DateTime time;
  String title;

  Post({
    required this.author,
    required this.description,
    required this.email,
    required this.likes,
    required this.name,
    required this.postId,
    required this.propic,
    required this.subjectTitle,
    required this.time,
    required this.title,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      author: map['author'],
      description: map['description'],
      email: map['email'],
      likes: List<String>.from(map['likes']),
      name: map['name'],
      postId: map['postId'],
      propic: map['proPic'],
      subjectTitle: map['subjectTitle'],
      time: map['time'].toDate(),
      title: map['title'],
    );
  }
}
