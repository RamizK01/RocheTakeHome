import os
import pandas as pd
from typing import Dict, List, Any
from langchain_openai import ChatOpenAI
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Load the AE dataset
AE_DATA = pd.read_csv('ae.csv')

# Schema Definition - Describes all relevant columns for the LLM
SCHEMA_DEFINITION = """
# Adverse Events (AE) Dataset Schema

## Key Columns:
- USUBJID: Unique Subject ID (identifier for patients)
- STUDYID: Study Identifier
- DOMAIN: Domain (always 'AE' for Adverse Events)
- AESEV: Adverse Event Severity (MILD, MODERATE, SEVERE)
- AESER: Serious Adverse Event (Y=Yes, N=No)
- AETERM: Adverse Event Term (the name/condition of the AE - e.g., headache, rash)
- AESOC: System Organ Class / Body System (e.g., Nervous System, Skin and Subcutaneous Tissue)
- AEREL: Relationship/Causality (PROBABLE, POSSIBLE, REMOTE, NONE)
- AEOUT: Outcome (RECOVERED/RESOLVED, NOT RECOVERED/NOT RESOLVED, FATAL, UNKNOWN)
- AEACN: Action Taken (drug dose reduced, drug dose increased, drug discontinued, etc.)
- AESTDY: Adverse Event Start Day
- AESTDTC: Adverse Event Start Date/Time
- AEENDTC: Adverse Event End Date/Time

## Available unique values for key columns:
"""

# Build schema with sample values
for col in ['AESEV', 'AESER', 'AETERM', 'AESOC', 'AEREL', 'AEOUT']:
    if col in AE_DATA.columns:
        unique_vals = AE_DATA[col].dropna().unique().tolist()[:10]
        SCHEMA_DEFINITION += f"\n- {col}: {unique_vals}"


class ClinicalTrialDataAgent:
    """
    An LLM-powered agent that parses natural language questions about adverse events
    and returns filtered subject data.
    """
    
    def __init__(self):
        """Initialize the agent with LLM"""
        self.llm = ChatOpenAI(
            model="gpt-4o",
            temperature=0.2,
            api_key=os.getenv("OPENAI_API_KEY")
        )
    
    def parse_question(self, question: str) -> Dict[str, Any]:
        """
        Use LLM to parse a user's question into structured JSON output.
        
        Args:
            question: Natural language question about adverse events
            
        Returns:
            Dictionary with target_column and filter_value
        """
        prompt = f"""
        You are a clinical data analysis expert. Parse the user's question about adverse events data.
        
        Dataset Schema:
        {SCHEMA_DEFINITION}
        
        User Question: {question}
        
        Return ONLY a valid JSON object (no markdown, no extra text) with exactly these fields:
        {{
            "target_column": "<the column name to filter on, e.g., AESEV>",
            "filter_value": "<the value to search for>"
        }}
        
        Important:
        - If asking about "severe", target_column is AESEV and filter_value is SEVERE
        - If asking about "headache", target_column is AETERM and filter_value is HEADACHE
        - If asking about "recovered", target_column is AEOUT and filter_value is RECOVERED/RESOLVED
        - Always use uppercase for values
        """
        
        try:
            response = self.llm.invoke(prompt)
            # Extract JSON from response
            response_text = response.content.strip()
            
            if not response_text:
                raise ValueError("Empty response from LLM")
            
            # Try to parse as JSON
            parsed = json.loads(response_text)
            return parsed
        except json.JSONDecodeError as e:
            return {
                "error": f"Failed to parse LLM response as JSON: {str(e)}",
                "raw_response": response_text if 'response_text' in locals() else "No response"
            }
        except Exception as e:
            return {"error": str(e)}
    
    def execute_filter(self, target_column: str, filter_value: str) -> Dict[str, Any]:
        """
        Apply the filter to the AE dataframe and return matching subjects.
        
        Args:
            target_column: The column to filter on
            filter_value: The value to search for
            
        Returns:
            Dictionary with count of unique subjects and list of matching IDs
        """
        if target_column not in AE_DATA.columns:
            return {
                "success": False,
                "error": f"Column '{target_column}' not found in dataset",
                "available_columns": list(AE_DATA.columns)
            }
        
        try:
            # Filter the data - handle case-insensitive matching for string columns
            if AE_DATA[target_column].dtype == 'object':
                filtered = AE_DATA[AE_DATA[target_column].astype(str).str.upper() == filter_value.upper()]
            else:
                filtered = AE_DATA[AE_DATA[target_column] == filter_value]
            
            # Get unique subject IDs
            unique_subjects = filtered['USUBJID'].dropna().unique().tolist()
            
            return {
                "success": True,
                "filter_applied": f"{target_column} = {filter_value}",
                "matching_records": len(filtered),
                "unique_subjects": len(unique_subjects),
                "subject_ids": unique_subjects,
                "sample_data": filtered[[col for col in ['USUBJID', 'AETERM', 'AESEV', 'AESOC'] if col in AE_DATA.columns]].head(5).to_dict('records')
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def query(self, question: str) -> Dict[str, Any]:
        """
        End-to-end query: parse question and execute filter.
        
        Args:
            question: Natural language question
            
        Returns:
            Results with subject count and IDs
        """
        # Step 1: Parse the question using LLM
        parsed = self.parse_question(question)
        
        if "error" in parsed:
            return {
                "success": False,
                "question": question,
                "error": parsed.get("error")
            }
        
        # Step 2: Execute the filter
        target_column = parsed.get("target_column")
        filter_value = parsed.get("filter_value")
        
        result = self.execute_filter(target_column, filter_value)
        result["question"] = question
        result["parsed_intent"] = {
            "target_column": target_column,
            "filter_value": filter_value
        }
        
        return result