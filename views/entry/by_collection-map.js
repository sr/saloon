function(doc) {
  if ( doc.type == "collection" ) {
    emit([doc._id, 0], doc);
  } else if ( doc.type == "entry" ) {
    emit([doc.collection, 1], doc);
  }
}
