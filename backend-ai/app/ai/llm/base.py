from abc import ABC, abstractmethod
from typing import Optional, Type
from pydantic import BaseModel

class BaseLLM(ABC):
    @abstractmethod
    async def generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        """
        Generate text response from the LLM.
        
        Args:
            system_prompt: The system instruction prompt.
            user_prompt: The patient data and analysis context prompt.
            response_format: Optional Pydantic model to enforce structured output.
            
        Returns:
            The raw text or JSON response string.
        """
        pass
