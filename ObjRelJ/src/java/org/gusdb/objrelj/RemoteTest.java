package org.gusdb.objrelj;

import java.util.*;
import org.gusdb.model.DoTS.*;
import org.gusdb.model.SRes.*;

import org.biojava.bio.*;
import org.biojava.bio.seq.*;
import org.biojava.bio.seq.io.*;
import org.biojava.bio.symbol.*;

/**
 * RemoteTest.java
 *
 * A simple test program for the Java object layer that relies
 * on a <B>remote</B> JDBC connection to the database. Derived from
 * Jonathan Crabtree's LocalTest class
 *
 * @author Jonathan Crabtree, Dave Barkan
 * @version $Revision$ $Date$ $Author$
 */
public class RemoteTest {

    // ------------------------------------------------------------------
    // main()
    // ------------------------------------------------------------------
    
    public static void main(String args[]) {

	if (args.length != 3) {
	    System.out.println("Usage: java org.gusdb.objrelj.RemoteTest rmiUrl gusUser gusPassword");
	    System.exit(1);
	}

	String rmiUrl = args[0];
	String gusUser = args[1];
	String gusPassword = args[2];

	DatabaseDriverI driver = new RemoteDatabaseDriver(rmiUrl);
	ServerI server = new GUSServer(driver);
	String s1 = null;

	try {

	    // Open connection using a local JDBC adapter
	    //
	    s1 = server.openConnection(gusUser, gusPassword);

	    // Retrieve and print the contents of a small table.
	    // 
	    Vector objs = server.retrieveAllObjects(s1, "DoTS", "SequenceType");
	    System.out.println("Retrieved " + objs.size() + " objects: \n");
	    Iterator i = objs.iterator();

	    while (i.hasNext()) {
		GUSRow obj = (GUSRow)i.next();
		System.out.println(obj.toString());
		//		System.out.println(obj.toXML());
	    }

	    // Retrieve a specific ExternalNASequence (M69198)
	    //
	    ExternalNASequence naseq1 = (ExternalNASequence)(server.retrieveObject(s1, "DoTS", "ExternalNASequence", 50130249));
	    System.out.println(naseq1.toXML());
	    long seqLen = naseq1.getSequenceLobLength().longValue();
	    System.out.println("Cached sequence = " + naseq1.getSequenceLobCached());

	    printFasta(naseq1,70);
	    printFasta(naseq1,70,0,(int)seqLen);

	    // Try converting to BioJava SymbolList
	    //
	    SymbolList sl1 = naseq1.getSequenceAsSymbolList();
	    printSymbolList(sl1);

	    SymbolList sl2 = naseq1.getSequenceAsSymbolList(70,139);
	    printSymbolList(sl2);

	    // Retrieve another ExternalNASequence, but only the first 500bp of its sequence (Y00864)
	    //
	    ExternalNASequence naseq2 = (ExternalNASequence)(server.retrieveObject(s1, "DoTS", "ExternalNASequence", 85319819, 
										   "sequence", new Long(0), new Long(600)));
	    System.out.println(naseq2.toXML());
	    System.out.println("Cached sequence = " + naseq2.getSequenceLobCached());
	    printFasta(naseq2,70,0,500);
	    printFasta(naseq2,70,140,500);

	    // This should fail:
	    printFasta(naseq2,70,0,700);

	} catch (Throwable t) {
	    System.err.println(t.getMessage());
	    t.printStackTrace(System.err);
	}
	try {
	    server.closeConnection(s1);
	} catch (GUSNoConnectionException nce) {}
    }

    // Generate FASTA file for a subsequence of the specified NASequence;
    // uses NASequence.getSequence (long start, long end)
    //
    public static void printFasta(NASequence seq, int charsPerLine, int first, int last) {
	String descr = seq.getDescription();
	long seqLen = seq.getSequenceLobLength().longValue();

	System.out.println(">" + descr + " (sequence length = " + seqLen + ", showing " + first + "-" + (last-1) + ")");

	for (int i = first;i < last - 1;i += charsPerLine) {
	    int end = i + charsPerLine - 1;
	    if (end > (last - 1)) end = last - 1;
	    char[] subseq = seq.getSequence(i, end);
	    int requestLen = end - i + 1;
	    System.out.println(new String(subseq));
	}
    }

    // Generate FASTA file for an entire NASequence.
    //
    public static void printFasta(NASequence seq, int charsPerLine) {
	char seqArray[] = seq.getSequence();
	int seqLen = seqArray.length;
	String descr = seq.getDescription();

	System.out.println(">" + descr + " (sequence length = " + seqLen + ")");

	for (int i = 0;i < seqLen;i += charsPerLine) {
	    int end = i + charsPerLine - 1;
	    if (end > (seqLen - 1)) end = seqLen - 1;
	    System.out.println(new String(seqArray, i, end - i + 1));
	}
    }

    // Print a BioJava SymbolList
    //
    public static void printSymbolList(SymbolList sl) {
	try {
	    FiniteAlphabet dnaAlphabet = DNATools.getDNA();
	    SymbolTokenization dnaToke = dnaAlphabet.getTokenization("token");
	    String seqString = dnaToke.tokenizeSymbolList(sl);
	    System.out.println("SymbolList = " + seqString);    
	} 
	catch (Exception e) {
	    e.printStackTrace(System.err);
	}
    }

}
