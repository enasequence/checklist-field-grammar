grammar ChecklistCondition;

@lexer::header
{
	package uk.ac.ebi.ena.sra.validation.checklist.condition;
}


@parser::header
{
	package uk.ac.ebi.ena.sra.validation.checklist.condition;
	import java.util.HashMap;
	import java.util.ArrayList;
	import org.slf4j.Logger;
    import org.slf4j.LoggerFactory;
}

@parser::members
{
    static Logger logger = LoggerFactory.getLogger(ChecklistConditionParser.class);
	private HashMap<String, ArrayList<String>> fieldsAndValues = new HashMap<String, ArrayList<String>>();
	private static final String FILTER_REGEX = "[,;\\s_:.#\\\\\\/]";
	
	public void addField(String name)
	{
		addField(name, null);
	}

	public void addField(String name, String value)
	{
		name = normaliseName( name );	
		ArrayList<String> values = fieldsAndValues.get(name);		
		if ( values == null ) 
		{
			values = new ArrayList<String>();
			fieldsAndValues.put(name, values);
		}
		values.add( value );
	}

	public void resetFields()
	{
		fieldsAndValues.clear();
	}	
	
	private String normaliseName( String name )
	{
		return name.toUpperCase().replaceAll("^\"|\"$", "");		
	}

	private String getFilterString (String string) {
         if (string != null) {
            return string.replaceAll(FILTER_REGEX,"");
         } else {
             return null;
         }
    }
}

condition returns [boolean result]
	:
	lhs=expr DEPENDENCY rhs=expr
	{
		// If lhs is true then rhs side must be true.
		logger.trace("DEBUG: lhs=expr DEPENDENCY rhs=expr");
	
		if ( $lhs.result )
			$result = $rhs.result;
		else
			$result = true;
	} 
|	lhs=expr
	{
		// lhs must be true.	
		logger.trace("DEBUG: lhs=expr:" + $lhs.result);
		$result = $lhs.result;
	};

expr returns [boolean result]
	:
	lhs=expr AND rhs=expr
	{
		logger.trace("DEBUG: lhs=expr AND rhs=expr");
	
		$result = $lhs.result && $rhs.result;
	}
| 	lhs=expr OR rhs=expr
 	{
		logger.trace("DEBUG: lhs=expr OR rhs=expr");
 	
 		$result = $lhs.result || $rhs.result;
    }
| 	lhs=expr XOR rhs=expr
 	{
		logger.trace("DEBUG: lhs=expr XOR rhs=expr");

 		$result = ( ( $lhs.result || $rhs.result ) && ! ( $lhs.result && $rhs.result ) );
    }
|<assoc=right> NOT lhs=expr
 	{
		logger.trace("DEBUG: NOT lhs=expr");
 	
 		$result = ! $lhs.result;
    }
| 	LPAR lhs=expr RPAR
	{
		logger.trace("DEBUG: LPAR lhs=expr RPAR");
	
		$result = $lhs.result; 
	}
| 	TRUE
	{
		logger.trace("DEBUG: TRUE");
	
		$result = true; 
	}
| 	FALSE
	{
		logger.trace("DEBUG: FALSE");
	
		$result = false; 
	}
| 	name=STRING
	{
		logger.trace("DEBUG: name=STRING");
	
		// Check that $name.text field is defined.
		String name = $name.text;
		name = normaliseName( name );
		ArrayList<String> values = fieldsAndValues.get( name );
		$result = false;
		if ( values != null )
		{
			for (String value : values) {
				if (value != null) {
					value = getFilterString( value );
					if (value.length() > 0) {
						$result = true;
						logger.trace("DEBUG: known field");
						break;
					}
				}
			}
		}

	}
    ('=' regex=STRING
	{
	
		logger.trace("DEBUG: regex=STRING");
			
		// Check that $name.text field is defined and matches against $regex.text regex.
		//String name = $name.text;
		String regex = $regex.text;
		regex = regex.replaceAll("^\"|\"$", "");

		// ArrayList<String> values = fieldsAndValues.get( name );

		if ( null == values )
		{
			$result = false;
		}
		else
		{
			for ( String value : values )
			{
				if ( value == null )
				{
					logger.trace(String.format("DEBUG: no value to match regex %s against", regex));
					$result = false;
					break;
				}
				else
				{
					logger.trace(String.format("DEBUG: value=%s, regex=%s", value, regex));
					$result = value.matches( regex );
				}
			}
		}
	}	
	)?
;

DEPENDENCY: '->';
LPAR: '(';
RPAR: ')';
OR: 'or';
XOR: 'xor';
AND: 'and';
NOT: 'not';
EQUALS: '=';
TRUE: 'true';
FALSE: 'false';
STRING: ('"' (~'"')* '"') | [a-zA-Z_][a-zA-Z_0-9]*;
WS : [ \r\t\n]+ -> skip ;
