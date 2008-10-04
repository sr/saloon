function(doc) {
  if ( doc.type == "collection" ) {
    emit(doc._id, doc);
  }
}
