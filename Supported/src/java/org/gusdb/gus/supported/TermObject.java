package org.gusdb.gus.supported;

import java.util.ArrayList;

/** 
 * 	Information of an OWL entity, current used by OntologyVisitor.java 
 *
 *  @author Jie Zheng
 */
public class TermObject implements Comparable<TermObject>{
	private String id;
	private String label;
	private String iriStr;
	private String synonyms;
	private String definition;
	private String type;
	private ArrayList<String> parents;
	private boolean is_obsolete;

	
	public TermObject () {
		this.id = null;
		this.label = null;
		this.iriStr = null;
		this.synonyms = null;
		this.definition = null;
		this.is_obsolete = false;
		this.type = "class";
		this.parents = new ArrayList<String>();	
	}
	
	public TermObject (String id, String label, String definition, String iriStr, String synonyms, boolean is_obsolete, String type) {
		this.id = id;
		this.label = label;
		this.iriStr = iriStr;
		this.synonyms = synonyms;
		this.definition = definition;
		this.is_obsolete = is_obsolete;
		this.type = type;
	}
	
	public void setId (String id) {
		this.id = id;		
	}
	
	public String getId (){
		return id;
	}

	public void setLabel (String label) {
		this.label = label;		
	}
	
	public String getLabel (){
		return label;
	}
	
	public void setDefinition (String definition) {
		this.definition = definition;		
	}
	
	public String getDefinition (){
		return definition;
	}

	public void setSynonyms (String synonyms) {
		this.synonyms = synonyms;		
	}
	
	public String getSynonyms (){
		return synonyms;
	}
	
	public void setIriStr (String iriStr) {
		this.iriStr = iriStr;		
	}
	
	public String getIriStr (){
		return iriStr;
	}

	public void setType (String type) {
		this.type = type;		
	}
	
	public String getType (){
		return type;
	}	
	
	public void addParent (String parent) {
		this.parents.add(parent);		
	}
	
	public ArrayList<String> getParents (){
		return parents;
	}
	
	public void setObsoleteStatus (boolean is_obsolete) {
		this.is_obsolete = is_obsolete;		
	}
	
	public boolean getIs_obsolete (){
		return is_obsolete;
	}
	
	public int compareTo(TermObject term)
    {
        return getIriStr().compareTo(term.getIriStr());
    }
	
	// this method is used by OntologyVisitor.java for generation of BCGO required output, might not fit other applications 
	public String toString()
	{
		String infoStr = getId() + "\t" + getLabel() + "\t" + getDefinition() + "\t" + getSynonyms() + "\t" + getIriStr() + "\t" + getIs_obsolete();
		return infoStr;
	}
}
