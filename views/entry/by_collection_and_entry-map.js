function(doc) {
  if ( doc.type == "entry" ) {
    emit([doc.collection, doc._id], doc);
  }
}
