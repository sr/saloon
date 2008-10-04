function(doc) {
  if ( doc.type == "entry" ) {
    emit([doc._id, doc.collection], doc);
  }
}
