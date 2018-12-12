FROM liabifano/executor:bd0ce94

COPY setup.py /__job-python__/
COPY requirements.txt /__job-python__/
COPY src/ /__job-python__/src/

RUN find . | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf
RUN pip install -U -r __job-python__/requirements.txt
RUN pip install __job-python__/.
