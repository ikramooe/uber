class History {
  String pickup;
  String destination;
  String fares;
  String status;
  DateTime createdAt;

  History({
    this.pickup,
    this.destination,
    this.fares,
    this.status,
    this.createdAt,
  });

  History.fromSnapshot(snapshot) {
    this.pickup = snapshot.data()['pickup']['place'];
    this.destination = snapshot.data()['destination']['place'];
    this.fares = snapshot.data()['prix'].toString();
    
    this.status = snapshot.data()['status'];
  }
}
