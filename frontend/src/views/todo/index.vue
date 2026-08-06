<template>
  <div class="app-container">
    <el-card shadow="never" class="filter-container">
      <el-form :inline="true" :model="query" class="search-form">
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width: 120px">
            <el-option label="全部" value="all" />
            <el-option label="未完成" value="undone" />
            <el-option label="已完成" value="done" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级">
          <el-select v-model="query.priority" placeholder="全部" clearable style="width: 120px">
            <el-option label="高" value="high" />
            <el-option label="中" value="normal" />
            <el-option label="低" value="low" />
          </el-select>
        </el-form-item>
        <el-form-item label="关键词">
          <el-input v-model="query.keyword" placeholder="标题或备注" clearable style="width: 180px" @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">搜索</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never" class="table-container">
      <div class="toolbar">
        <el-button type="primary" :icon="Plus" @click="handleAdd">新增待办</el-button>
        <el-button :icon="Upload" @click="importDialogVisible = true">导入</el-button>
        <el-button :icon="Download" @click="handleExport">导出</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="selection" width="50" align="center" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="标题" min-width="200" show-overflow-tooltip>
          <template #default="{ row }">
            <span :style="{ textDecoration: row.done ? 'line-through' : 'none', color: row.done ? '#c0c4cc' : '#303133' }">
              {{ row.title }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="priority" label="优先级" width="90" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="priorityType(row.priority)">{{ priorityText(row.priority) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-switch
              :model-value="row.done"
              @change="handleToggle(row, $event)"
              active-text="完成"
              inactive-text="未完成"
              inline-prompt
            />
          </template>
        </el-table-column>
        <el-table-column prop="creator" label="创建人" width="100" align="center" />
        <el-table-column prop="assignee" label="负责人" width="100" align="center" />
        <el-table-column prop="dueDate" label="截止时间" width="160" />
        <el-table-column prop="createTime" label="创建时间" width="170" />
        <el-table-column prop="completedAt" label="完成时间" width="170" />
        <el-table-column prop="remark" label="备注" min-width="180" show-overflow-tooltip />
        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="query.page"
          v-model:page-size="query.size"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>

    <el-dialog v-model="importDialogVisible" title="导入待办事项" width="480px" @close="resetImport">
      <div class="import-content">
        <div class="template-tip">
          <el-button type="primary" link :icon="Download" @click="handleDownloadTemplate">下载导入模板</el-button>
        </div>
        <el-upload
          ref="uploadRef"
          class="import-upload"
          :show-file-list="false"
          :before-upload="handleImport"
          :auto-upload="true"
          accept=".xlsx,.xls,.csv"
          drag
        >
          <el-icon class="el-icon--upload"><upload-filled /></el-icon>
          <div class="el-upload__text">
            将文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              支持 .xlsx / .xls / .csv 格式，单个文件不超过 10MB
            </div>
          </template>
        </el-upload>
      </div>
      <template #footer>
        <el-button @click="importDialogVisible = false">取消</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" @close="resetForm">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="88px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="form.title" placeholder="请输入待办标题" />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="优先级" prop="priority">
              <el-radio-group v-model="form.priority">
                <el-radio value="high">高</el-radio>
                <el-radio value="normal">中</el-radio>
                <el-radio value="low">低</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="负责人">
              <el-input v-model="form.assignee" placeholder="请输入负责人" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="截止时间" prop="dueDate">
          <el-date-picker
            v-model="form.dueDate"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm"
            placeholder="选择截止时间"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="已完成">
          <el-switch v-model="form.done" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, Download, Edit, Plus, Refresh, Search, Upload, UploadFilled } from '@element-plus/icons-vue'
import { createTodo, deleteTodo, getTodoPage, toggleTodoDone, updateTodo, exportTodo, importTodo, downloadTodoTemplate } from '@/api/app/todo'

const loading = ref(false)
const submitLoading = ref(false)
const tableData = ref([])
const total = ref(0)

const importDialogVisible = ref(false)
const uploadRef = ref()

const query = reactive({
  keyword: '',
  status: 'all',
  priority: '',
  page: 1,
  size: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('')
const formRef = ref()
const form = reactive({
  id: null,
  title: '',
  priority: 'normal',
  dueDate: '',
  remark: '',
  done: false,
  assignee: ''
})

const rules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }]
}

function normalizeTodo(row = {}) {
  const done = row.done !== undefined ? Boolean(row.done) : Boolean(row.completed)
  return {
    id: row.id,
    title: row.title || '',
    priority: row.priority || 'normal',
    dueDate: row.dueDate || row.due_date || '',
    remark: row.remark || '',
    done,
    completed: done ? 1 : 0,
    creator: row.creator || '',
    assignee: row.assignee || '',
    completedAt: row.completedAt || row.completed_at || '',
    createTime: row.createTime || row.created_at || '',
    updateTime: row.updateTime || row.updated_at || ''
  }
}

async function loadData() {
  loading.value = true
  try {
    const params = {
      page: query.page,
      size: query.size,
      keyword: query.keyword,
      status: query.status,
      priority: query.priority
    }
    const res = await getTodoPage(params)
    const records = res.data?.records || res.data?.list || []
    tableData.value = records.map(normalizeTodo)
    total.value = res.data?.total || 0
  } catch (error) {
    tableData.value = []
    total.value = 0
    ElMessage.error(error.response?.data?.detail || error.message || '待办查询失败')
  } finally {
    loading.value = false
  }
}

function priorityText(priority) {
  return { high: '高', normal: '中', low: '低' }[priority] || '中'
}

function priorityType(priority) {
  return { high: 'danger', normal: 'warning', low: 'info' }[priority] || 'info'
}

function handleSearch() {
  query.page = 1
  loadData()
}

function handleReset() {
  query.keyword = ''
  query.status = 'all'
  query.priority = ''
  query.page = 1
  handleSearch()
}

function handleAdd() {
  dialogTitle.value = '新增待办'
  Object.assign(form, {
    id: null,
    title: '',
    priority: 'normal',
    dueDate: '',
    remark: '',
    done: false,
    assignee: ''
  })
  dialogVisible.value = true
}

function handleEdit(row) {
  dialogTitle.value = '编辑待办'
  Object.assign(form, normalizeTodo(row))
  dialogVisible.value = true
}

function resetForm() {
  formRef.value?.resetFields()
}

async function submitForm() {
  await formRef.value.validate()
  submitLoading.value = true
  try {
    const payload = {
      title: form.title.trim(),
      priority: form.priority,
      due_date: form.dueDate || null,
      remark: form.remark || '',
      completed: form.done ? 1 : 0,
      assignee: form.assignee || ''
    }
    if (form.id) {
      await updateTodo(form.id, payload)
      ElMessage.success('待办已更新')
    } else {
      await createTodo(payload)
      ElMessage.success('待办已新增')
    }
    dialogVisible.value = false
    await loadData()
  } catch (error) {
    ElMessage.error(error.response?.data?.detail || error.message || '待办保存失败')
  } finally {
    submitLoading.value = false
  }
}

async function handleToggle(item, checked) {
  const nextDone = Boolean(checked)
  item.done = nextDone
  item.completed = nextDone ? 1 : 0
  try {
    const res = await toggleTodoDone(item.id, { completed: nextDone ? 1 : 0 })
    Object.assign(item, normalizeTodo(res.data || item))
    ElMessage.success(nextDone ? '已标记完成' : '已恢复为未完成')
  } catch (error) {
    item.done = !nextDone
    item.completed = item.done ? 1 : 0
    ElMessage.error(error.response?.data?.detail || error.message || '状态更新失败')
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除“${row.title}”吗？`, '提示', { type: 'warning' })
    await deleteTodo(row.id)
    ElMessage.success('删除成功')
    await loadData()
  } catch (error) {
    if (error !== 'cancel' && error !== 'close') {
      ElMessage.error(error.response?.data?.detail || error.message || '删除失败')
    }
  }
}

async function handleImport(file) {
  try {
    const res = await importTodo(file)
    if (res.code === 200) {
      ElMessage.success(`导入成功，共 ${res.data?.count || 0} 条数据`)
      importDialogVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.detail || '导入失败')
    }
  } catch (error) {
    if (error !== 'cancel' && error !== 'close') {
      ElMessage.error(error.response?.data?.detail || error.message || '导入失败')
    }
  }
  return false
}

async function handleExport() {
  try {
    const params = {
      keyword: query.keyword,
      status: query.status,
      priority: query.priority
    }
    const res = await exportTodo(params)
    const blob = res.data
    const url = window.URL.createObjectURL(new Blob([blob]))
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', 'todos.xlsx')
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch (error) {
    ElMessage.error(error.message || '导出失败')
  }
}

async function handleDownloadTemplate() {
  try {
    const res = await downloadTodoTemplate()
    const blob = res.data
    const url = window.URL.createObjectURL(new Blob([blob]))
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', 'todo_template.xlsx')
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('模板下载成功')
  } catch (error) {
    ElMessage.error(error.message || '模板下载失败')
  }
}

function resetImport() {
  uploadRef.value?.clearFiles?.()
}

onMounted(loadData)
</script>

<style scoped>
.filter-container {
  margin-bottom: 16px;
}

.search-form {
  margin: 0;
}

.toolbar {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.import-content {
  padding: 8px 0;
}

.import-upload {
  margin-bottom: 16px;
}

.template-tip {
  margin-bottom: 16px;
}
</style>
