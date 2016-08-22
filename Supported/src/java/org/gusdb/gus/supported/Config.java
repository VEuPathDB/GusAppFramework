package org.gusdb.gus.supported;


/** 
 * 	Constants need for working with OWL format OBO Foundry ontologies
 *
 *  @author Jie Zheng
 */
public final class Config {
	// ontology location, URI or filePath + fileName
	public static final String OBI_URI = "http://purl.obolibrary.org/obo/obi.owl";
	public static final String OBI_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/obi/trunk/src/ontology/branches/obi.owl";
	public static final String OBI_MERGED_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/obi/releases/2011-04-20/merged/merged-obi-cleaned-subclasses.owl";
	public static final String IAO_URI = "http://purl.obolibrary.org/obo/iao/dev/iao-main.owl";
	public static final String OPL_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/PEO_PLO/opl.owl";
	public static final String OPL_INFERRED_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/PEO_PLO/opl_inferred.owl";	
	public static final String FGED_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/obi/releases/2011-04-20/merged/FGED_obi_merged.owl";
	public static final String OBI_FGED_VIEW_FILE_NAME = "C:/Documents and Settings/Jie/My Documents/Ontology/obi/releases/2011-04-20/merged/obi-fgedView_ontoFox_ind.owl";
	
	// annotation properties
	public static final String DEF_AnnotProp = "http://purl.obolibrary.org/obo/IAO_0000115";
	public static final String IAO_SYN_AnnotProp = "http://purl.obolibrary.org/obo/IAO_0000118";
	public static final String OBO_SYN_AnnotProp = "http://purl.obolibrary.org/obo#Synonym";
	public static final String BROAD_SYN_AnnotProp = "http://www.geneontology.org/formats/oboInOwl#hasBroadSynonym";
	public static final String EXACT_SYN_AnnotProp = "http://www.geneontology.org/formats/oboInOwl#hasExactSynonym";
	public static final String NARROW_SYN_AnnotProp = "http://www.geneontology.org/formats/oboInOwl#hasNarrowSynonym";
	public static final String RELATE_SYN_AnnotProp = "http://www.geneontology.org/formats/oboInOwl#hasRelatedSynonym";
	public static final String FGED_SYN_AnnotProp = "http://purl.obolibrary.org/obo/OBI_9991119";
	public static final String IEDB_SYN_AnnotProp = "http://purl.obolibrary.org/obo/OBI_9991118";
	public static final String IMPORT_FROM_AnnotProp = "http://purl.obolibrary.org/obo/IAO_0000412";
	public static final String PREFERRED_TERM_AnnotPorp = "http://purl.obolibrary.org/obo/IAO_0000111";
	public static final String EDITOR_AnnotPorp = "http://purl.obolibrary.org/obo/IAO_0000117";
	public static final String Deprecated_AnnotPorp =  "http://www.w3.org/2002/07/owl#deprecated";
	public static final String OBSOLETE_CLASS = "http://www.geneontology.org/formats/oboInOwl#ObsoleteClass";
	public static final String OBSOLETE_PROP = "http://www.geneontology.org/formats/oboInOwl#ObsoleteProperty";
	
	public static final String EFO_SYN_AnnotProp = "http://www.ebi.ac.uk/efo/alternative_term";
	public static final String EFO_DEF_AnnotProp = "http://www.ebi.ac.uk/efo/definition";		
}
