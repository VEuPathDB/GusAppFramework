package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.Ordering;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;



public class Protocol {
  private String name;
  private boolean addition;
  private String dbId;
  private OntologyTerm type;
  private OntologyTerm sourceId;
  private String description;
  private String pubmedId;
  private String isPrivate;
  private String uri;
  private String contactId;
  private List<ProtocolParam> parameters;
  private static Map<String, List<String>> comments;
  private static List<Protocol> protocols;
  public static Logger logger = LoggerFactory.getLogger(Protocol.class);
  public static final String URI_COMMENT = "Protocol Uri";
  public static final String PUBMED_ID_COMMENT = "Protocol Pubmed Id";
  public static final String PRIVATE_COMMENT = "Is Private Protocol";
  public static final String SOURCE_ID_COMMENT = "Protocol Source Id";
  public static final String EXT_DB_RLS_COMMENT = "Protocol ExtDbRls";
  
  public Protocol() {
    addition = false;
    dbId = "";
  }
  
  public String getName() {
    return name;
  }
  public final void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }
  
  public final boolean isAddition() {
    return addition;
  }
  public void setAddition(boolean addition) {
    this.addition = addition;
  }
  public final String getDbId() {
    return dbId;
  }
  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }
  public OntologyTerm getType() {
    return type;
  }
  public void setType(OntologyTerm type) {
    this.type = type;
  }

  public String getDescription() {
    return description;
  }
  public void setDescription(String description) {
    this.description = AppUtils.removeTokens(description);
  }
  public String getPubmedId() {
    return pubmedId;
  }
  public void setPubmedId(String pubmedId) {
    this.pubmedId = AppUtils.removeTokens(pubmedId);
  }
  public String getUri() {
    return uri;
  }
  public void setUri(String uri) {
    this.uri = AppUtils.removeTokens(uri);
  }
  public String getContactId() {
    return contactId;
  }
  public void setContactId(String contactId) {
    this.contactId = AppUtils.removeTokens(contactId);
  }
  public OntologyTerm getSourceId() {
    return sourceId;
  }
  public void setSourceId(OntologyTerm sourceId) {
    this.sourceId = sourceId;
  }
  public List<ProtocolParam> getParameters() {
	return parameters;
  }
  public void setParameters(List<ProtocolParam> parameters) {
	this.parameters = parameters;
  }
  public String getIsPrivate() {
    return isPrivate;
  }
  public void setIsPrivate(String isPrivate) {
    this.isPrivate = AppUtils.removeTokens(isPrivate);
  }
  
  public static final List<Protocol> getProtocols() {
    return protocols;
  }

  public static final void setProtocols(List<Protocol> protocols) {
    Protocol.protocols = protocols;
  }

  @Override
  public String toString() {
    return new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE).toString();
  }
  
  public static void setComments(IDF data) {
    comments = new HashMap<String,List<String>>();
    comments.put(URI_COMMENT, OrderedComment.retrieveComments(URI_COMMENT, data));
    comments.put(PUBMED_ID_COMMENT, OrderedComment.retrieveComments(PUBMED_ID_COMMENT, data));
    comments.put(PRIVATE_COMMENT, OrderedComment.retrieveComments(PRIVATE_COMMENT, data));
    comments.put(SOURCE_ID_COMMENT, OrderedComment.retrieveComments(SOURCE_ID_COMMENT, data));
    comments.put(EXT_DB_RLS_COMMENT, OrderedComment.retrieveComments(EXT_DB_RLS_COMMENT, data));
  }
  
  public static Map<String, List<String>> getComments() {
    return comments;
  }
  
  public static int longestAttribute(final IDF data) {
    List<Integer> sizes = new ArrayList<>();
    if(comments == null) setComments(data);
    Iterator<String> iterator = comments.keySet().iterator();
    while(iterator.hasNext()) {
      String key = iterator.next();
      sizes.add(comments.get(key).size());
    }
    sizes.add(data.protocolName.size());
    sizes.add(data.protocolType.size());
    sizes.add(data.protocolDescription.size());
    sizes.add(data.protocolContact.size());
    return Ordering.<Integer> natural().max(sizes);
  }
  
  /**
   * Assembles the IDF protocol names for use in validation.  Addition/id tokens are filtered out.
   * @param data - IDF data
   * @return - Set of filtered protocol names found in the IDF
   */
  public static Set<String> getProtocolNames(final IDF data) {
    Set<String> protocolNames = new HashSet<String>();
    Iterator<String> iterator = data.protocolName.iterator();
    while(iterator.hasNext()) {
      // Strip add/id tokens if present
      String filtered = AppUtils.removeTokens(iterator.next());
      protocolNames.add(filtered);
    }
    return protocolNames;
  }
  
  /**
   * Convenience method used by ProtocolSeries to determine whether a ProtocolSeries is an addition.  If
   * the protocol included by the series is an addition, then the series is an addition.
   * @param name - name of protocol being sought
   * @return - the protocol sought or null if no protocol exists having the given name.
   */
  public static Protocol getProtocolByName(String name) {
    for(Protocol protocol : protocols) {
      if(protocol.name != null && protocol.name.equals(name)) {
        return protocol;
      }
    }
    return null;
  }

  public static List<Protocol> populate(IDF data) throws ConversionException {
	logger.debug("START: Populating Protocols");
	if(comments == null) setComments(data);

    protocols = new ArrayList<>();
    Iterator<String> iterator = data.protocolName.iterator();
    for(int i = 0; iterator.hasNext(); i++) {
      String name = iterator.next();
      Protocol protocol = new Protocol();
      protocol.setName(name);
      protocol.setAddition(AppUtils.checkForAddition(name));
      protocol.setDbId(AppUtils.filterIdToken(name));
      protocol.setType(new OntologyTerm(ListUtils.get(data.protocolType, i), ListUtils.get(data.protocolTermSourceREF, i)));
      protocol.setDescription(ListUtils.get(data.protocolDescription, i));
      protocol.setContactId(ListUtils.get(data.protocolContact, i));
      protocol.setUri(ListUtils.get(comments.get(URI_COMMENT), i));
      protocol.setPubmedId(ListUtils.get(comments.get(PUBMED_ID_COMMENT), i));
      protocol.setIsPrivate(ListUtils.get(comments.get(PRIVATE_COMMENT), i));
      protocol.setSourceId(new OntologyTerm(ListUtils.get(comments.get(SOURCE_ID_COMMENT), i),ListUtils.get(comments.get(EXT_DB_RLS_COMMENT), i)));
      protocol.setParameters(ProtocolParam.populate(data, i));
      protocols.add(protocol);
    }
    logger.debug("END: Populating Protocols");
    return protocols;
  }
}
